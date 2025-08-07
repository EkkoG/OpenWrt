use serde::{Deserialize, Serialize};
use std::process::Command;
use tauri::command;

#[derive(Debug, Serialize, Deserialize)]
pub struct DockerInfo {
    pub installed: bool,
    pub running: bool,
    pub version: String,
    pub compose_installed: bool,
    pub compose_version: String,
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
    match Command::new("docker").arg("version").arg("--format").arg("{{.Server.Version}}").output() {
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
                if let Ok(client_output) = Command::new("docker").arg("version").arg("--format").arg("{{.Client.Version}}").output() {
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
    match Command::new("docker").arg("compose").arg("version").output() {
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
        match Command::new("docker-compose").arg("version").output() {
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
    match Command::new("docker").arg("info").output() {
        Ok(output) => Ok(output.status.success()),
        Err(_) => Ok(false),
    }
}