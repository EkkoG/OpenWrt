use serde::{Deserialize, Serialize};
use std::process::{Command, Stdio};
use std::sync::Mutex;
use std::io::{BufRead, BufReader};
use tauri::{command, AppHandle, Emitter};
use std::thread;
use crate::app_mode::get_current_mode;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BuildConfig {
    pub image: String,
    pub profile: Option<String>,  // profile 是可选的
    pub modules: Vec<String>,
    pub output_dir: String,
    pub env_vars: Vec<EnvVar>,
    pub global_env_vars: String,  // 全局环境变量字符串
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EnvVar {
    pub key: String,
    pub value: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BuildEvent {
    pub event_type: String, // "log", "progress", "complete", "error"
    pub data: String,
    pub progress: Option<u32>,
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
        let env_file_path = base_path.join("modules").join(&module_name).join(".env");
        
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
        let root_env_path = base_path.join(".env");
        
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
    let run_script_path = mode.get_script_path(&app, "run.sh")?;
    
    cmd.current_dir(&base_path)  // 切换到资源基础目录
       .arg(&run_script_path)
       .arg(format!("--image={}", &config.image));
    
    // 如果指定了 profile，添加 profile 参数
    if let Some(profile) = &config.profile {
        if !profile.is_empty() {
            cmd.arg(format!("--profile={}", profile));
        }
    }
    
    cmd.env("ENABLE_MODULES", modules_str)
       .env("OUTPUT_DIR", &config.output_dir)
       .stdout(Stdio::piped())
       .stderr(Stdio::piped());

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
            progress: Some(0),
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
                        progress: None,
                    });

                    // 尝试解析进度
                    if line.contains("Progress:") || line.contains("进度:") {
                        if let Some(progress) = parse_progress(&line) {
                            let _ = app_clone.emit("build-event", BuildEvent {
                                event_type: "progress".to_string(),
                                data: line,
                                progress: Some(progress),
                            });
                        }
                    }
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
                        progress: None,
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
                        progress: Some(100),
                    });
                } else {
                    let _ = app_clone.emit("build-event", BuildEvent {
                        event_type: "error".to_string(),
                        data: format!("[构建失败] 退出码: {:?}", status.code()),
                        progress: None,
                    });
                }
            }
            Err(e) => {
                let mut process_lock = BUILD_PROCESS.lock().unwrap();
                *process_lock = None;
                
                let _ = app_clone.emit("build-event", BuildEvent {
                    event_type: "error".to_string(),
                    data: format!("[构建失败] {}", e),
                    progress: None,
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

fn parse_progress(line: &str) -> Option<u32> {
    // 尝试从日志行中提取进度百分比
    // 例如: "Progress: 50%" 或 "进度: 50%"
    if let Some(pos) = line.find('%') {
        let start = line[..pos].rfind(char::is_numeric)?;
        let num_str = &line[start..pos];
        num_str.parse::<u32>().ok()
    } else {
        None
    }
}