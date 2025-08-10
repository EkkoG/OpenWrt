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
        // 检测是否在开发环境 - 需要同时检查modules和setup目录
        // tauri-app 在项目子目录中，需要向上两层到达项目根目录
        println!("当前目录: {:?}", std::env::current_dir().unwrap());
        // 当前目录: "/xx/openwrt/tauri-app/src-tauri"
        if Path::new("../../modules").exists() && Path::new("../../setup").exists() {
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
                // 打包后的资源在 _up_/_up_/ 目录下
                Ok(resource_dir.join("_up_").join("_up_"))
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

    pub fn get_setup_path(&self, app_handle: &AppHandle) -> Result<PathBuf, String> {
        let base_path = self.get_resource_base_path(app_handle)?;
        Ok(base_path.join("setup"))
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
        
        // 强制重建：先删除现有目录
        if extract_dir.exists() {
            fs::remove_dir_all(&extract_dir)
                .map_err(|e| format!("Failed to remove existing directory: {}", e))?;
        }

        // 需要提取资源
        fs::create_dir_all(&extract_dir)
            .map_err(|e| format!("Failed to create extract directory: {}", e))?;

        // 使用 get_resource_base_path 获取正确的源路径
        let source_base_path = self.get_resource_base_path(app_handle)?;

        // 复制脚本文件
        let build_script_src = source_base_path.join("build.sh");
        let run_script_src = source_base_path.join("run.sh");
        
        if build_script_src.exists() {
            fs::copy(&build_script_src, extract_dir.join("build.sh"))
                .map_err(|e| format!("Failed to copy build.sh: {}", e))?;
        }
        
        if run_script_src.exists() {
            fs::copy(&run_script_src, extract_dir.join("run.sh"))
                .map_err(|e| format!("Failed to copy run.sh: {}", e))?;
        }

        // 提取setup目录
        let setup_src = source_base_path.join("setup");
        let setup_dst = extract_dir.join("setup");
        
        if setup_src.exists() {
            self.copy_dir_recursive(&setup_src, &setup_dst)?;
        }

        // 提取模块目录
        let modules_src = source_base_path.join("modules");
        let modules_dst = extract_dir.join("modules");
        
        if modules_src.exists() {
            self.copy_dir_recursive(&modules_src, &modules_dst)?;
        }

        // 创建custom_modules目录
        let custom_modules_dir = extract_dir.join("custom_modules");
        fs::create_dir_all(&custom_modules_dir)
            .map_err(|e| format!("Failed to create custom_modules directory: {}", e))?;

        // 更新状态
        let mut resource_lock = RESOURCE_PATH.lock().unwrap();
        *resource_lock = Some(extract_dir);
        
        let mut mode_lock = CURRENT_MODE.lock().unwrap();
        *mode_lock = Some(AppMode::Portable);

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

#[command]
pub async fn verify_setup_directory(app: AppHandle) -> Result<String, String> {
    let mode = get_current_mode();
    let setup_path = mode.get_setup_path(&app)?;
    
    if !setup_path.exists() {
        return Ok(format!("Setup directory not found at: {}", setup_path.display()));
    }
    
    // 检查build-setup.sh是否存在
    let build_setup_script = setup_path.join("build-setup.sh");
    let build_setup_exists = build_setup_script.exists();
    
    // 检查keys目录是否存在
    let keys_dir = setup_path.join("keys");
    let keys_exists = keys_dir.exists();
    let keys_count = if keys_exists {
        fs::read_dir(&keys_dir)
            .map_err(|e| format!("Failed to read keys directory: {}", e))?
            .count()
    } else {
        0
    };
    
    Ok(format!(
        "Setup directory: {} (exists: {})\nBuild script: {} (exists: {})\nKeys directory: {} (exists: {}, files: {})",
        setup_path.display(),
        setup_path.exists(),
        build_setup_script.display(),
        build_setup_exists,
        keys_dir.display(),
        keys_exists,
        keys_count
    ))
}