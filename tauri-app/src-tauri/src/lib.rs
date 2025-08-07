mod docker;
mod modules;
mod build;

use docker::{check_docker_environment, check_docker_running};
use modules::{get_modules, read_module_packages, save_module_env};
use build::{start_build, cancel_build, is_building};

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
            is_building
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
