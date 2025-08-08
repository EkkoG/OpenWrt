use serde::{Deserialize, Serialize};
use std::process::Command;
use std::path::Path;
use tauri::command;

#[derive(Debug, Serialize, Deserialize)]
pub struct DockerInfo {
    pub installed: bool,
    pub running: bool,
    pub version: String,
    pub compose_installed: bool,
    pub compose_version: String,
}

// 查找 Docker 可执行文件路径
fn find_docker_command() -> String {
    let docker_paths = vec![
        "/usr/local/bin/docker",           // Intel Mac Homebrew
        "/opt/homebrew/bin/docker",        // Apple Silicon Homebrew  
        "/Applications/Docker.app/Contents/Resources/bin/docker", // Docker Desktop
        "/usr/bin/docker",                  // 系统路径
    ];
    
    for path in docker_paths {
        if Path::new(path).exists() {
            return path.to_string();
        }
    }
    
    // 如果都找不到，返回 docker，让系统报错
    "docker".to_string()
}

// 查找 Docker Compose 可执行文件路径
fn find_docker_compose_command() -> String {
    let compose_paths = vec![
        "/usr/local/bin/docker-compose",
        "/opt/homebrew/bin/docker-compose",
        "/Applications/Docker.app/Contents/Resources/bin/docker-compose",
    ];
    
    for path in compose_paths {
        if Path::new(path).exists() {
            return path.to_string();
        }
    }
    
    "docker-compose".to_string()
}

#[command]
pub async fn check_docker_environment() -> Result<DockerInfo, String> {
    let mut info = DockerInfo {
        installed: false,
        running: false,
        version: String::new(),
        compose_installed: false,
        compose_version: String::new(),
    };

    // Check Docker installation and version
    let docker_cmd = find_docker_command();
    match Command::new(&docker_cmd).arg("version").arg("--format").arg("{{.Server.Version}}").output() {
        Ok(output) => {
            if output.status.success() {
                info.installed = true;
                info.running = true;
                info.version = String::from_utf8_lossy(&output.stdout).trim().to_string();
            } else {
                // Docker is installed but daemon is not running
                info.installed = true;
                info.running = false;
                
                // Try to get client version
                if let Ok(client_output) = Command::new(&docker_cmd).arg("version").arg("--format").arg("{{.Client.Version}}").output() {
                    if client_output.status.success() {
                        info.version = String::from_utf8_lossy(&client_output.stdout).trim().to_string();
                    }
                }
            }
        }
        Err(_) => {
            // Docker is not installed
            info.installed = false;
        }
    }

    // Check Docker Compose (new version: docker compose)
    match Command::new(&docker_cmd).arg("compose").arg("version").output() {
        Ok(output) => {
            if output.status.success() {
                info.compose_installed = true;
                let version_str = String::from_utf8_lossy(&output.stdout);
                // Parse version from output like "Docker Compose version v2.20.0"
                if let Some(version) = version_str.split_whitespace().last() {
                    info.compose_version = version.trim_start_matches('v').to_string();
                }
            }
        }
        Err(_) => {}
    }

    // If new compose is not found, check legacy docker-compose
    if !info.compose_installed {
        let compose_cmd = find_docker_compose_command();
        match Command::new(&compose_cmd).arg("version").output() {
            Ok(output) => {
                if output.status.success() {
                    info.compose_installed = true;
                    let version_str = String::from_utf8_lossy(&output.stdout);
                    // Parse version from output like "docker-compose version 1.29.2, build 5becea4c"
                    if let Some(line) = version_str.lines().next() {
                        if let Some(version_part) = line.split("version").nth(1) {
                            if let Some(version) = version_part.split(',').next() {
                                info.compose_version = version.trim().to_string();
                            }
                        }
                    }
                }
            }
            Err(_) => {}
        }
    }

    Ok(info)
}

#[command]
pub async fn check_docker_running() -> Result<bool, String> {
    let docker_cmd = find_docker_command();
    match Command::new(&docker_cmd).arg("info").output() {
        Ok(output) => Ok(output.status.success()),
        Err(_) => Ok(false),
    }
}