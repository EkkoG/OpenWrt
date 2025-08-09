use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use tauri::{command, AppHandle, Manager};
use anyhow::Result;

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    pub theme: Option<String>,
    pub auto_check_updates: Option<bool>,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            theme: Some("light".to_string()),
            auto_check_updates: Some(true),
        }
    }
}

pub struct SettingsManager {
    settings_file: PathBuf,
}

impl SettingsManager {
    pub fn new(app_handle: &AppHandle) -> Result<Self> {
        let app_dir = app_handle.path().app_config_dir()?;
        let settings_file = app_dir.join("settings.json");
        
        // 确保配置目录存在
        if let Some(parent) = settings_file.parent() {
            fs::create_dir_all(parent)?;
        }
        
        Ok(Self { settings_file })
    }
    
    pub fn load_settings(&self) -> Result<AppSettings> {
        if !self.settings_file.exists() {
            return Ok(AppSettings::default());
        }
        
        let content = fs::read_to_string(&self.settings_file)?;
        let settings: AppSettings = serde_json::from_str(&content)?;
        Ok(settings)
    }
    
    pub fn save_settings(&self, settings: &AppSettings) -> Result<()> {
        let content = serde_json::to_string_pretty(settings)?;
        fs::write(&self.settings_file, content)?;
        Ok(())
    }
    
}

#[command]
pub async fn get_app_settings(app: AppHandle) -> Result<AppSettings, String> {
    let manager = SettingsManager::new(&app).map_err(|e| e.to_string())?;
    manager.load_settings().map_err(|e| e.to_string())
}

#[command]
pub async fn update_app_settings(app: AppHandle, settings: AppSettings) -> Result<AppSettings, String> {
    let manager = SettingsManager::new(&app).map_err(|e| e.to_string())?;
    manager.save_settings(&settings).map_err(|e| e.to_string())?;
    Ok(settings)
}

