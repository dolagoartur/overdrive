use serde::Deserialize;
use specta::Type;

#[derive(Type, Deserialize, Clone, Copy, Debug)]
pub enum AppThemeType {
	Auto = -1,
	Light = 0,
	Dark = 1,
}

#[tauri::command(async)]
#[specta::specta]
#[allow(unused_variables)]
pub async fn lock_app_theme(theme_type: AppThemeType) {
	// println!("Lock theme, type: {theme_type:?}")
}
