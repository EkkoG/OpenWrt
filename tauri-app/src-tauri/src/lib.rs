mod docker;
mod modules;
mod build;
mod app_mode;
mod config_manager;

use docker::{check_docker_environment, check_docker_running};
use modules::{get_modules, read_module_packages, get_module_readme, save_module_env};
use build::{start_build, cancel_build, is_building};
use app_mode::{get_app_mode_info, reinitialize_app_mode, initialize_app_mode, verify_setup_directory};
use config_manager::{ConfigManager, Configuration, BuildConfig};

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
async fn get_configurations(app_handle: tauri::AppHandle) -> Result<Vec<Configuration>, String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.get_configurations().map_err(|e| e.to_string())
}

#[tauri::command]
async fn save_configuration(
    app_handle: tauri::AppHandle,
    name: String,
    description: String,
    config: BuildConfig,
) -> Result<Configuration, String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.save_configuration(name, description, config).map_err(|e| e.to_string())
}

#[tauri::command]
async fn update_configuration(
    app_handle: tauri::AppHandle,
    id: String,
    updates: serde_json::Value,
) -> Result<Configuration, String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.update_configuration(id, updates).map_err(|e| e.to_string())
}

#[tauri::command]
async fn delete_configuration(app_handle: tauri::AppHandle, id: String) -> Result<(), String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.delete_configuration(id).map_err(|e| e.to_string())
}

#[tauri::command]
async fn switch_configuration(app_handle: tauri::AppHandle, id: String) -> Result<(), String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.switch_configuration(id).map_err(|e| e.to_string())
}

#[tauri::command]
async fn duplicate_configuration(
    app_handle: tauri::AppHandle,
    id: String,
    new_name: String,
) -> Result<Configuration, String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.duplicate_configuration(id, new_name).map_err(|e| e.to_string())
}

#[tauri::command]
async fn export_configuration(
    app_handle: tauri::AppHandle,
    id: String,
    path: String,
) -> Result<(), String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.export_configuration(id, path).map_err(|e| e.to_string())
}

#[tauri::command]
async fn import_configuration(
    app_handle: tauri::AppHandle,
    path: String,
) -> Result<Configuration, String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.import_configuration(path).map_err(|e| e.to_string())
}

#[tauri::command]
async fn deactivate_configuration(
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    let manager = ConfigManager::new(&app_handle).map_err(|e| e.to_string())?;
    manager.deactivate_configuration().map_err(|e| e.to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            greet,
            check_docker_environment,
            check_docker_running,
            get_modules,
            read_module_packages,
            get_module_readme,
            save_module_env,
            start_build,
            cancel_build,
            is_building,
            get_app_mode_info,
            reinitialize_app_mode,
            verify_setup_directory,
            get_configurations,
            save_configuration,
            update_configuration,
            delete_configuration,
            switch_configuration,
            duplicate_configuration,
            export_configuration,
            import_configuration,
            deactivate_configuration
        ])
        .setup(|app| {
            // 初始化应用模式
            if let Err(e) = initialize_app_mode(app.handle()) {
                eprintln!("Failed to initialize app mode: {}", e);
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
