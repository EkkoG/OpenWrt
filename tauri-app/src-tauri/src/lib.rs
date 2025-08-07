mod docker;
mod modules;
mod build;
mod app_mode;

use docker::{check_docker_environment, check_docker_running};
use modules::{get_modules, read_module_packages, save_module_env};
use build::{start_build, cancel_build, is_building};
use app_mode::{get_app_mode_info, reinitialize_app_mode, initialize_app_mode};

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
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
            save_module_env,
            start_build,
            cancel_build,
            is_building,
            get_app_mode_info,
            reinitialize_app_mode
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
