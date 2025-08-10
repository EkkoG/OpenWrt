use serde::{Deserialize, Serialize};
use std::process::{Command, Stdio};
use std::sync::Mutex;
use std::io::{BufRead, BufReader};
use tauri::{command, AppHandle, Emitter, Manager};
use std::thread;
use crate::app_mode::get_current_mode;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AdvancedOptions {
    pub with_pull: bool,
    pub rm_first: bool,
    pub use_mirror: bool,
    pub mirror_url: String,
    pub custom_args: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BuildConfig {
    pub image: String,
    pub profile: Option<String>,  // profile 是可选的
    pub modules: Vec<String>,
    pub output_dir: String,
    pub env_vars: Vec<EnvVar>,
    pub global_env_vars: String,  // 全局环境变量字符串
    pub advanced_options: Option<AdvancedOptions>,  // 高级选项
    pub custom_modules_path: Option<String>,  // 自定义模块路径
    pub rootfs_part_size: Option<u32>,  // RootFS 分区大小 (MB)，None 表示由 ImageBuilder 决定
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EnvVar {
    pub key: String,
    pub value: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BuildEvent {
    pub event_type: String, // "log", "complete", "error"
    pub data: String,
}

static BUILD_PROCESS: Mutex<Option<u32>> = Mutex::new(None);

#[command]
pub async fn start_build(
    app: AppHandle,
    config: BuildConfig
) -> Result<(), String> {
    // 检查是否已有构建在运行
    let mut process_lock = BUILD_PROCESS.lock().unwrap();
    if process_lock.is_some() {
        return Err("Build already in progress".to_string());
    }

    // 获取当前应用模式和基础路径
    let mode = get_current_mode();
    let base_path = mode.get_resource_base_path(&app)?;
    
    // 确定实际的工作目录
    // 在 Embedded 或 Portable 模式下，使用提取后的目录作为工作目录
    let working_dir = match mode {
        crate::app_mode::AppMode::Development => {
            // 将相对路径转换为绝对路径
            std::fs::canonicalize(&base_path)
                .map_err(|e| format!("Failed to canonicalize development path {}: {}", base_path.display(), e))?
        },
        crate::app_mode::AppMode::Embedded | crate::app_mode::AppMode::Portable => {
            // 使用 app_data_dir 中的提取目录
            let app_data_dir = app.path()
                .app_data_dir()
                .map_err(|e| format!("Failed to get app data directory: {}", e))?;
            let extract_dir = app_data_dir.join("openwrt-builder");
            
            // 确保目录存在
            if !extract_dir.exists() {
                // 如果不存在，触发资源提取
                mode.initialize(&app)?;
            }
            
            extract_dir
        }
    };
    
    // 为每个启用的模块写入 .env 文件
    let mut module_env_map: std::collections::HashMap<String, Vec<&crate::build::EnvVar>> = std::collections::HashMap::new();
    
    // 按模块分组环境变量
    for env_var in &config.env_vars {
        // 尝试从 key 中提取模块名，假设格式类似 MODULE_NAME_VARIABLE
        let module_name = if let Some(underscore_pos) = env_var.key.find('_') {
            env_var.key[..underscore_pos].to_lowercase()
        } else {
            // 如果没有下划线，可能整个 key 就是模块相关的
            continue;
        };
        
        module_env_map.entry(module_name).or_insert_with(Vec::new).push(env_var);
    }
    
    // 为每个模块写入 .env 文件
    for (module_name, env_vars) in module_env_map {
        let env_file_path = working_dir.join("modules").join(&module_name).join(".env");
        
        // 检查模块目录是否存在
        if let Some(parent) = env_file_path.parent() {
            if parent.exists() {
                let mut content = String::new();
                for env_var in env_vars {
                    content.push_str(&format!("{}={}\n", env_var.key, env_var.value));
                }
                
                if let Err(e) = std::fs::write(&env_file_path, content) {
                    eprintln!("Failed to write .env file for module {}: {}", module_name, e);
                } else {
                    println!("Written .env file for module: {}", module_name);
                }
            }
        }
    }
    
    // 写入全局环境变量到根目录的 .env 文件
    if !config.global_env_vars.trim().is_empty() {
        let root_env_path = working_dir.join(".env");
        
        if let Err(e) = std::fs::write(&root_env_path, &config.global_env_vars) {
            eprintln!("Failed to write global .env file: {}", e);
        } else {
            println!("Written global .env file to: {}", root_env_path.display());
        }
    }

    // 准备环境变量
    let modules_str = config.modules.join(" ");
    
    // 构建命令
    let mut cmd = Command::new("bash");
    let run_script_path = working_dir.join("run.sh");  // 使用工作目录中的 run.sh
    
    println!("Working directory: {}", working_dir.display());
    println!("Run script path: {}", run_script_path.display());
    println!("Run script exists: {}", run_script_path.exists());
    
    cmd.current_dir(&working_dir)  // 切换到工作目录
       .arg(&run_script_path)
       .arg(format!("--image={}", &config.image));
    
    // 如果指定了 profile，添加 profile 参数
    if let Some(profile) = &config.profile {
        if !profile.is_empty() {
            cmd.arg(format!("--profile={}", profile));
        }
    }
    
    // 添加高级选项参数
    if let Some(advanced) = &config.advanced_options {
        if advanced.with_pull {
            cmd.arg("--with-pull");
        }
        
        if advanced.rm_first {
            cmd.arg("--rm-first");
        }
        
        if advanced.use_mirror {
            if !advanced.mirror_url.is_empty() {
                cmd.arg(format!("--use-mirror"));
                cmd.arg(format!("--mirror={}", advanced.mirror_url));
            } else {
                cmd.arg("--use-mirror");
            }
        }
        
        // 处理自定义参数
        if !advanced.custom_args.is_empty() {
            let custom_args: Vec<&str> = advanced.custom_args.split_whitespace().collect();
            for arg in custom_args {
                cmd.arg(arg);
            }
        }
    }
    
    // 从配置中获取自定义模块路径
    if let Some(custom_modules_path) = &config.custom_modules_path {
        if !custom_modules_path.is_empty() {
            cmd.arg(format!("--custom-modules={}", custom_modules_path));
        }
    }
    
    cmd.env("ENABLE_MODULES", modules_str)
       .env("OUTPUT_DIR", &config.output_dir)
       .stdout(Stdio::piped())
       .stderr(Stdio::piped());
    
    // 添加 RootFS 分区大小配置
    if let Some(rootfs_size) = config.rootfs_part_size {
        cmd.env("CONFIG_TARGET_ROOTFS_PARTSIZE", rootfs_size.to_string());
    }

    // 添加自定义环境变量
    for env_var in config.env_vars {
        cmd.env(env_var.key, env_var.value);
    }

    // 启动进程
    let mut child = cmd.spawn().map_err(|e| format!("Failed to start build: {}", e))?;
    
    // 保存进程 ID
    let pid = child.id();
    *process_lock = Some(pid);
    drop(process_lock);

    // 克隆 app handle 用于事件发送
    let app_clone = app.clone();
    
    // 在新线程中处理输出
    thread::spawn(move || {
        // 发送开始事件
        let _ = app_clone.emit("build-event", BuildEvent {
            event_type: "log".to_string(),
            data: "[构建开始]".to_string(),
        });

        // 读取标准输出
        if let Some(stdout) = child.stdout.take() {
            let reader = BufReader::new(stdout);
            for line in reader.lines() {
                if let Ok(line) = line {
                    // 发送日志事件
                    let _ = app_clone.emit("build-event", BuildEvent {
                        event_type: "log".to_string(),
                        data: line.clone(),
                    });

                }
            }
        }

        // 读取标准错误
        if let Some(stderr) = child.stderr.take() {
            let reader = BufReader::new(stderr);
            for line in reader.lines() {
                if let Ok(line) = line {
                    let _ = app_clone.emit("build-event", BuildEvent {
                        event_type: "log".to_string(),
                        data: format!("[ERROR] {}", line),
                    });
                }
            }
        }

        // 等待进程结束
        match child.wait() {
            Ok(status) => {
                let mut process_lock = BUILD_PROCESS.lock().unwrap();
                *process_lock = None;
                
                if status.success() {
                    let _ = app_clone.emit("build-event", BuildEvent {
                        event_type: "complete".to_string(),
                        data: "[构建成功完成]".to_string(),
                    });
                } else {
                    let _ = app_clone.emit("build-event", BuildEvent {
                        event_type: "error".to_string(),
                        data: format!("[构建失败] 退出码: {:?}", status.code()),
                    });
                }
            }
            Err(e) => {
                let mut process_lock = BUILD_PROCESS.lock().unwrap();
                *process_lock = None;
                
                let _ = app_clone.emit("build-event", BuildEvent {
                    event_type: "error".to_string(),
                    data: format!("[构建失败] {}", e),
                });
            }
        }
    });

    Ok(())
}

#[command]
pub async fn cancel_build() -> Result<(), String> {
    let mut process_lock = BUILD_PROCESS.lock().unwrap();
    
    if let Some(pid) = process_lock.take() {
        // 尝试终止进程
        #[cfg(unix)]
        {
            let _ = Command::new("kill")
                .arg("-TERM")
                .arg(pid.to_string())
                .spawn();
        }
        
        #[cfg(windows)]
        {
            let _ = Command::new("taskkill")
                .arg("/F")
                .arg("/PID")
                .arg(pid.to_string())
                .spawn();
        }
        
        Ok(())
    } else {
        Err("No build in progress".to_string())
    }
}

#[command]
pub async fn is_building() -> Result<bool, String> {
    let process_lock = BUILD_PROCESS.lock().unwrap();
    Ok(process_lock.is_some())
}

