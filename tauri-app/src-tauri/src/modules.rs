use serde::{Deserialize, Serialize};
use std::fs;
use tauri::{command, AppHandle};
use crate::app_mode::get_current_mode;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ModuleInfo {
    pub name: String,
    pub path: String,
    pub has_packages: bool,
    pub has_env_example: bool,
    pub has_readme: bool,
    pub has_files: bool,
    pub has_scripts: Vec<String>,
    pub env_vars: Vec<EnvVariable>,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EnvVariable {
    pub name: String,
    pub value: String,
    pub description: String,
}

#[command]
pub async fn get_modules(app: AppHandle) -> Result<Vec<ModuleInfo>, String> {
    let mode = get_current_mode();
    let modules_path = mode.get_modules_path(&app)?;
    
    if !modules_path.exists() {
        return Err("Modules directory not found".to_string());
    }
    
    let mut modules = Vec::new();
    
    let entries = fs::read_dir(modules_path).map_err(|e| e.to_string())?;
    
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        
        if path.is_dir() {
            let module_name = path.file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_string();
            
            if module_name.is_empty() {
                continue;
            }
            
            let module_path = path.to_str().unwrap_or("").to_string();
            
            // Check for packages file
            let has_packages = path.join("packages").exists();
            
            // Check for example.env file
            let env_example_path = path.join("example.env");
            let has_env_example = env_example_path.exists();
            
            // Parse environment variables from example.env
            let mut env_vars = Vec::new();
            if has_env_example {
                if let Ok(content) = fs::read_to_string(&env_example_path) {
                    for line in content.lines() {
                        let line = line.trim();
                        if !line.is_empty() && !line.starts_with('#') {
                            if let Some(eq_pos) = line.find('=') {
                                let name = line[..eq_pos].trim().to_string();
                                let value = line[eq_pos + 1..].trim().to_string();
                                env_vars.push(EnvVariable {
                                    name: name.clone(),
                                    value,
                                    description: format!("{} configuration", name),
                                });
                            }
                        }
                    }
                }
            }
            
            // Check for README.md
            let readme_path = path.join("README.md");
            let has_readme = readme_path.exists();
            
            // Get description from README if available
            let mut description = String::new();
            if has_readme {
                if let Ok(content) = fs::read_to_string(&readme_path) {
                    description = extract_description_from_readme(&content);
                }
            }
            
            // If no description from README, generate one based on module name
            if description.is_empty() {
                description = generate_description(&module_name);
            }
            
            // Check for files directory
            let has_files = path.join("files").exists();
            
            // Check for script files
            let mut has_scripts = Vec::new();
            if let Ok(entries) = fs::read_dir(&path) {
                for entry in entries {
                    if let Ok(entry) = entry {
                        let file_name = entry.file_name();
                        if let Some(name) = file_name.to_str() {
                            if name.ends_with(".sh") {
                                has_scripts.push(name.to_string());
                            }
                        }
                    }
                }
            }
            
            modules.push(ModuleInfo {
                name: module_name,
                path: module_path,
                has_packages,
                has_env_example,
                has_readme,
                has_files,
                has_scripts,
                env_vars,
                description,
            });
        }
    }
    
    // Sort modules by name
    modules.sort_by(|a, b| a.name.cmp(&b.name));
    
    Ok(modules)
}

fn extract_description_from_readme(content: &str) -> String {
    let lines: Vec<&str> = content.lines().collect();
    
    // 查找第一个 ## 功能 或 ## 功能说明 或 ## 描述 部分
    for (i, line) in lines.iter().enumerate() {
        let line = line.trim();
        if line.starts_with("## 功能") || line.starts_with("## 描述") || line.starts_with("## 说明") {
            // 获取下一行作为描述
            if i + 1 < lines.len() {
                let desc = lines[i + 1].trim();
                if !desc.is_empty() && !desc.starts_with('#') {
                    return desc.to_string();
                }
            }
        }
    }
    
    // 如果没找到功能部分，查找第一行非标题内容
    for line in lines {
        let line = line.trim();
        if !line.is_empty() && !line.starts_with('#') && !line.starts_with("```") {
            return line.to_string();
        }
    }
    
    String::new()
}

fn generate_description(module_name: &str) -> String {
    match module_name {
        "add-all-device-to-lan" => "将所有设备添加到 LAN 网络".to_string(),
        "add-feed-base" => "添加基础软件源".to_string(),
        "add-feed-key" => "添加软件源密钥".to_string(),
        "add-feed" => "添加自定义软件源".to_string(),
        "argon" => "Argon 主题配置".to_string(),
        "base" => "基础软件包".to_string(),
        "base23" => "OpenWrt 23.x 基础软件包".to_string(),
        "base24+" => "OpenWrt 24.x+ 基础软件包".to_string(),
        "daed" => "DAE 代理工具".to_string(),
        "daed-as-default" => "设置 DAE 为默认代理".to_string(),
        "ib" => "ImageBuilder 配置".to_string(),
        "lan" => "LAN 网络配置".to_string(),
        "nikki-as-default" => "设置 Mihomo 为默认代理".to_string(),
        "nikki-ekko-prefer" => "Mihomo 偏好设置".to_string(),
        "openclash" => "OpenClash 代理工具".to_string(),
        "openclash-as-default" => "设置 OpenClash 为默认代理".to_string(),
        "openclash-stun-direct" => "OpenClash STUN 直连配置".to_string(),
        "openwrt-nikki" => "OpenWrt Mihomo 集成".to_string(),
        "opkg-mirror" => "OPKG 镜像源配置".to_string(),
        "passwall" => "PassWall 代理工具".to_string(),
        "pppoe" => "PPPoE 拨号配置".to_string(),
        "prefer-ipv6-settings" => "IPv6 优先设置".to_string(),
        "python" => "Python 运行环境".to_string(),
        "reject-netflix-ipv6" => "拒绝 Netflix IPv6 连接".to_string(),
        "root-password" => "Root 密码设置".to_string(),
        "ssh-permission" => "SSH 权限配置".to_string(),
        "statistics" => "统计和监控工具".to_string(),
        "system" => "系统基础配置".to_string(),
        "tools" => "实用工具集".to_string(),
        _ => format!("{} 模块配置", module_name),
    }
}

#[command]
pub async fn read_module_packages(app: AppHandle, module_name: String) -> Result<Vec<String>, String> {
    let mode = get_current_mode();
    let modules_path = mode.get_modules_path(&app)?;
    let path = modules_path.join(&module_name).join("packages");
    
    if !path.exists() {
        return Ok(Vec::new());
    }
    
    let content = fs::read_to_string(path).map_err(|e| e.to_string())?;
    let packages: Vec<String> = content
        .lines()
        .map(|line| line.trim())
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(|line| line.to_string())
        .collect();
    
    Ok(packages)
}

#[command]
pub async fn get_module_readme(app: AppHandle, module_name: String) -> Result<String, String> {
    let mode = get_current_mode();
    let modules_path = mode.get_modules_path(&app)?;
    let readme_path = modules_path.join(&module_name).join("README.md");
    
    if !readme_path.exists() {
        return Err(format!("README.md not found for module: {}", module_name));
    }
    
    fs::read_to_string(&readme_path)
        .map_err(|e| format!("Failed to read README.md for module {}: {}", module_name, e))
}

#[command]
pub async fn save_module_env(app: AppHandle, module_name: String, env_vars: Vec<EnvVariable>) -> Result<(), String> {
    let mode = get_current_mode();
    let modules_path = mode.get_modules_path(&app)?;
    let path = modules_path.join(&module_name).join(".env");
    
    let mut content = String::new();
    for var in env_vars {
        content.push_str(&format!("{}={}\n", var.name, var.value));
    }
    
    fs::write(path, content).map_err(|e| e.to_string())?;
    
    Ok(())
}