use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use tauri::{command, AppHandle, Manager};
use std::sync::Mutex;

#[derive(Debug, Clone, PartialEq)]
pub enum AppMode {
    Development, // 开发模式 - 使用外部文件 (../../modules存在)
    Embedded,    // 单app模式 - 使用内置资源
    Portable,    // 便携模式 - 使用提取的资源
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AppModeInfo {
    pub mode: String,
    pub resource_path: String,
    pub working_directory: String,
    pub description: String,
}

static CURRENT_MODE: Mutex<Option<AppMode>> = Mutex::new(None);
static RESOURCE_PATH: Mutex<Option<PathBuf>> = Mutex::new(None);

impl AppMode {
    pub fn detect_mode() -> Self {
        // 检测是否在开发环境
        if Path::new("../../modules").exists() {
            AppMode::Development
        } else {
            AppMode::Embedded
        }
    }

    pub fn get_description(&self) -> String {
        match self {
            AppMode::Development => "开发模式：使用项目源码目录中的模块和脚本".to_string(),
            AppMode::Embedded => "单App模式：使用内置的构建资源".to_string(),
            AppMode::Portable => "便携模式：使用已提取的构建资源".to_string(),
        }
    }

    pub fn get_resource_base_path(&self, app_handle: &AppHandle) -> Result<PathBuf, String> {
        match self {
            AppMode::Development => Ok(PathBuf::from("../..")),
            AppMode::Embedded => {
                // 获取应用资源目录
                let resource_dir = app_handle
                    .path()
                    .resource_dir()
                    .map_err(|e| format!("Failed to get resource directory: {}", e))?;
                Ok(resource_dir)
            }
            AppMode::Portable => {
                let resource_lock = RESOURCE_PATH.lock().unwrap();
                if let Some(path) = resource_lock.as_ref() {
                    Ok(path.clone())
                } else {
                    Err("Portable mode resource path not initialized".to_string())
                }
            }
        }
    }

    pub fn get_modules_path(&self, app_handle: &AppHandle) -> Result<PathBuf, String> {
        let base_path = self.get_resource_base_path(app_handle)?;
        Ok(base_path.join("modules"))
    }

    pub fn get_script_path(&self, app_handle: &AppHandle, script_name: &str) -> Result<PathBuf, String> {
        let base_path = self.get_resource_base_path(app_handle)?;
        Ok(base_path.join(script_name))
    }

    pub fn initialize(&self, app_handle: &AppHandle) -> Result<(), String> {
        match self {
            AppMode::Development => {
                // 开发模式无需初始化
                Ok(())
            }
            AppMode::Embedded => {
                // 检查是否需要提取资源
                self.extract_resources_if_needed(app_handle)
            }
            AppMode::Portable => {
                // 便携模式应该已经初始化
                Ok(())
            }
        }
    }

    fn extract_resources_if_needed(&self, app_handle: &AppHandle) -> Result<(), String> {
        // 获取用户数据目录作为提取目标
        let app_data_dir = app_handle
            .path()
            .app_data_dir()
            .map_err(|e| format!("Failed to get app data directory: {}", e))?;

        let extract_dir = app_data_dir.join("openwrt-builder");
        
        // 检查是否已经提取过
        if extract_dir.join("modules").exists() && extract_dir.join("build.sh").exists() {
            // 已经提取过，切换到便携模式
            let mut resource_lock = RESOURCE_PATH.lock().unwrap();
            *resource_lock = Some(extract_dir);
            
            let mut mode_lock = CURRENT_MODE.lock().unwrap();
            *mode_lock = Some(AppMode::Portable);
            
            return Ok(());
        }

        // 需要提取资源
        fs::create_dir_all(&extract_dir)
            .map_err(|e| format!("Failed to create extract directory: {}", e))?;

        // 提取脚本文件
        let resource_dir = app_handle
            .path()
            .resource_dir()
            .map_err(|e| format!("Failed to get resource directory: {}", e))?;

        self.copy_resource_file(&resource_dir, &extract_dir, "build.sh")?;
        self.copy_resource_file(&resource_dir, &extract_dir, "run.sh")?;

        // 提取模块目录
        let modules_src = resource_dir.join("modules");
        let modules_dst = extract_dir.join("modules");
        
        if modules_src.exists() {
            self.copy_dir_recursive(&modules_src, &modules_dst)?;
        }

        // 创建user_modules目录
        let user_modules_dir = extract_dir.join("user_modules");
        fs::create_dir_all(&user_modules_dir)
            .map_err(|e| format!("Failed to create user_modules directory: {}", e))?;

        // 更新状态
        let mut resource_lock = RESOURCE_PATH.lock().unwrap();
        *resource_lock = Some(extract_dir);
        
        let mut mode_lock = CURRENT_MODE.lock().unwrap();
        *mode_lock = Some(AppMode::Portable);

        Ok(())
    }

    fn copy_resource_file(&self, src_dir: &Path, dst_dir: &Path, filename: &str) -> Result<(), String> {
        let src = src_dir.join(filename);
        let dst = dst_dir.join(filename);
        
        if src.exists() {
            fs::copy(&src, &dst)
                .map_err(|e| format!("Failed to copy {}: {}", filename, e))?;
        }
        
        Ok(())
    }

    fn copy_dir_recursive(&self, src: &Path, dst: &Path) -> Result<(), String> {
        if !src.exists() {
            return Ok(());
        }

        fs::create_dir_all(dst)
            .map_err(|e| format!("Failed to create directory {}: {}", dst.display(), e))?;

        let entries = fs::read_dir(src)
            .map_err(|e| format!("Failed to read directory {}: {}", src.display(), e))?;

        for entry in entries {
            let entry = entry.map_err(|e| format!("Failed to read directory entry: {}", e))?;
            let src_path = entry.path();
            let dst_path = dst.join(entry.file_name());

            if src_path.is_dir() {
                self.copy_dir_recursive(&src_path, &dst_path)?;
            } else {
                fs::copy(&src_path, &dst_path)
                    .map_err(|e| format!("Failed to copy file {}: {}", src_path.display(), e))?;
            }
        }

        Ok(())
    }
}

pub fn get_current_mode() -> AppMode {
    let mode_lock = CURRENT_MODE.lock().unwrap();
    mode_lock.clone().unwrap_or_else(|| AppMode::detect_mode())
}

pub fn initialize_app_mode(app_handle: &AppHandle) -> Result<AppMode, String> {
    let mode = AppMode::detect_mode();
    
    // 初始化模式
    mode.initialize(app_handle)?;
    
    // 保存当前模式
    let mut mode_lock = CURRENT_MODE.lock().unwrap();
    *mode_lock = Some(mode.clone());
    
    Ok(mode)
}

#[command]
pub async fn get_app_mode_info(app: AppHandle) -> Result<AppModeInfo, String> {
    let mode = get_current_mode();
    let resource_path = mode.get_resource_base_path(&app)?;
    let working_directory = std::env::current_dir()
        .map_err(|e| format!("Failed to get current directory: {}", e))?;

    Ok(AppModeInfo {
        mode: format!("{:?}", mode),
        resource_path: resource_path.to_string_lossy().to_string(),
        working_directory: working_directory.to_string_lossy().to_string(),
        description: mode.get_description(),
    })
}

#[command]
pub async fn reinitialize_app_mode(app: AppHandle) -> Result<AppModeInfo, String> {
    // 重新检测和初始化模式
    let mode = initialize_app_mode(&app)?;
    
    let resource_path = mode.get_resource_base_path(&app)?;
    let working_directory = std::env::current_dir()
        .map_err(|e| format!("Failed to get current directory: {}", e))?;

    Ok(AppModeInfo {
        mode: format!("{:?}", mode),
        resource_path: resource_path.to_string_lossy().to_string(),
        working_directory: working_directory.to_string_lossy().to_string(),
        description: mode.get_description(),
    })
}