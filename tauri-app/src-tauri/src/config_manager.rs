use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use anyhow::Result;
use tauri::Manager;

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ModuleConfig {
    pub name: String,
    pub enabled: bool,
    pub env_vars: std::collections::HashMap<String, String>,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct BuildConfig {
    pub selected_image: String,
    pub custom_image_tag: String,
    pub selected_profile: String,
    pub output_directory: String,
    pub global_env_vars: String,
    pub modules: Vec<ModuleConfig>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Configuration {
    pub id: String,
    pub name: String,
    pub description: String,
    pub config: BuildConfig,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub is_active: bool,
}

pub struct ConfigManager {
    config_dir: PathBuf,
}

impl ConfigManager {
    pub fn new(app_handle: &tauri::AppHandle) -> Result<Self> {
        let app_dir = app_handle.path().app_config_dir()?;
        let config_dir = app_dir.join("configurations");
        
        if !config_dir.exists() {
            fs::create_dir_all(&config_dir)?;
        }
        
        Ok(Self { config_dir })
    }

    pub fn get_configurations(&self) -> Result<Vec<Configuration>> {
        let mut configurations = Vec::new();
        
        if let Ok(entries) = fs::read_dir(&self.config_dir) {
            for entry in entries.flatten() {
                if let Some(ext) = entry.path().extension() {
                    if ext == "json" {
                        if let Ok(content) = fs::read_to_string(entry.path()) {
                            if let Ok(config) = serde_json::from_str::<Configuration>(&content) {
                                configurations.push(config);
                            }
                        }
                    }
                }
            }
        }
        
        configurations.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
        Ok(configurations)
    }

    pub fn save_configuration(&self, name: String, description: String, config: BuildConfig) -> Result<Configuration> {
        let id = Uuid::new_v4().to_string();
        let now = Utc::now();
        
        let configuration = Configuration {
            id: id.clone(),
            name,
            description,
            config,
            created_at: now,
            updated_at: now,
            is_active: false,
        };
        
        let file_path = self.config_dir.join(format!("{}.json", id));
        let content = serde_json::to_string_pretty(&configuration)?;
        fs::write(file_path, content)?;
        
        Ok(configuration)
    }

    pub fn update_configuration(&self, id: String, updates: serde_json::Value) -> Result<Configuration> {
        let file_path = self.config_dir.join(format!("{}.json", id));
        
        if !file_path.exists() {
            return Err(anyhow::anyhow!("Configuration not found"));
        }
        
        let content = fs::read_to_string(&file_path)?;
        let mut configuration: Configuration = serde_json::from_str(&content)?;
        
        if let Some(name) = updates.get("name").and_then(|v| v.as_str()) {
            configuration.name = name.to_string();
        }
        
        if let Some(description) = updates.get("description").and_then(|v| v.as_str()) {
            configuration.description = description.to_string();
        }
        
        if let Some(config) = updates.get("config") {
            configuration.config = serde_json::from_value(config.clone())?;
        }
        
        configuration.updated_at = Utc::now();
        
        let updated_content = serde_json::to_string_pretty(&configuration)?;
        fs::write(file_path, updated_content)?;
        
        Ok(configuration)
    }

    pub fn delete_configuration(&self, id: String) -> Result<()> {
        let file_path = self.config_dir.join(format!("{}.json", id));
        
        if file_path.exists() {
            fs::remove_file(file_path)?;
        }
        
        Ok(())
    }

    pub fn switch_configuration(&self, id: String) -> Result<()> {
        let mut configurations = self.get_configurations()?;
        
        for config in &mut configurations {
            config.is_active = config.id == id;
            
            let file_path = self.config_dir.join(format!("{}.json", config.id));
            let content = serde_json::to_string_pretty(&config)?;
            fs::write(file_path, content)?;
        }
        
        Ok(())
    }

    pub fn duplicate_configuration(&self, id: String, new_name: String) -> Result<Configuration> {
        let file_path = self.config_dir.join(format!("{}.json", id));
        
        if !file_path.exists() {
            return Err(anyhow::anyhow!("Configuration not found"));
        }
        
        let content = fs::read_to_string(&file_path)?;
        let original: Configuration = serde_json::from_str(&content)?;
        
        let new_id = Uuid::new_v4().to_string();
        let now = Utc::now();
        
        let new_configuration = Configuration {
            id: new_id.clone(),
            name: new_name,
            description: format!("复制自: {}", original.name),
            config: original.config,
            created_at: now,
            updated_at: now,
            is_active: false,
        };
        
        let new_file_path = self.config_dir.join(format!("{}.json", new_id));
        let new_content = serde_json::to_string_pretty(&new_configuration)?;
        fs::write(new_file_path, new_content)?;
        
        Ok(new_configuration)
    }

    pub fn export_configuration(&self, id: String, export_path: String) -> Result<()> {
        let file_path = self.config_dir.join(format!("{}.json", id));
        
        if !file_path.exists() {
            return Err(anyhow::anyhow!("Configuration not found"));
        }
        
        let content = fs::read_to_string(&file_path)?;
        fs::write(export_path, content)?;
        
        Ok(())
    }

    pub fn import_configuration(&self, import_path: String) -> Result<Configuration> {
        let content = fs::read_to_string(&import_path)?;
        let mut configuration: Configuration = serde_json::from_str(&content)?;
        
        configuration.id = Uuid::new_v4().to_string();
        configuration.created_at = Utc::now();
        configuration.updated_at = Utc::now();
        configuration.is_active = false;
        
        let file_path = self.config_dir.join(format!("{}.json", configuration.id));
        let new_content = serde_json::to_string_pretty(&configuration)?;
        fs::write(file_path, new_content)?;
        
        Ok(configuration)
    }
}