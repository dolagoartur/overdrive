use super::error::VolumeError;
use super::types::{DiskType, FileSystem, MountType, Volume};
use tokio::task;

// Re-export platform-specific get_volumes function
#[cfg(target_os = "linux")]
pub use self::linux::get_volumes;
#[cfg(any(target_os = "ios", target_os = "android"))]
pub use self::mobile::get_volumes;

// Re-export platform-specific unmount_volume function
#[cfg(target_os = "linux")]
pub use self::linux::unmount_volume;
#[cfg(any(target_os = "ios", target_os = "android"))]
pub use self::mobile::unmount_volume;

/// Common utilities for volume detection across platforms
mod common {
	pub fn parse_size(size_str: &str) -> u64 {
		size_str
			.chars()
			.filter(|c| c.is_ascii_digit())
			.collect::<String>()
			.parse()
			.unwrap_or(0)
	}

	pub fn is_virtual_filesystem(fs: &str) -> bool {
		matches!(
			fs.to_lowercase().as_str(),
			"devfs" | "sysfs" | "proc" | "tmpfs" | "ramfs" | "devtmpfs"
		)
	}
}


#[cfg(target_os = "linux")]
pub mod linux {
	use super::*;
	use std::{path::PathBuf, process::Command};
	use sysinfo::{DiskExt, System, SystemExt};

	pub async fn get_volumes() -> Result<Vec<Volume>, VolumeError> {
		let disk_info: Vec<(String, bool, PathBuf, Vec<u8>, u64, u64)> =
			tokio::task::spawn_blocking(|| {
				let mut sys = System::new_all();
				sys.refresh_disks_list();

				sys.disks()
					.iter()
					.filter(|disk| {
						!common::is_virtual_filesystem(
							std::str::from_utf8(disk.file_system()).unwrap_or(""),
						)
					})
					.map(|disk| {
						(
							disk.name().to_string_lossy().to_string(),
							disk.is_removable(),
							disk.mount_point().to_path_buf(),
							disk.file_system().to_vec(),
							disk.total_space(),
							disk.available_space(),
						)
					})
					.collect()
			})
			.await
			.map_err(|e| VolumeError::Platform(format!("Task join error: {}", e)))?;

		let mut volumes = Vec::new();
		for (name, is_removable, mount_point, file_system, total_space, available_space) in
			disk_info
		{
			if !mount_point.exists() {
				continue;
			}

			let read_only = is_volume_readonly(&mount_point)?;
			let disk_type = detect_disk_type(&name)?;

			volumes.push(Volume::new(
				name,
				if is_removable {
					MountType::External
				} else {
					MountType::System
				},
				mount_point.clone(),
				vec![mount_point],
				disk_type,
				FileSystem::from_string(&String::from_utf8_lossy(&file_system)),
				total_space,
				available_space,
				read_only,
			));
		}

		Ok(volumes)
	}

	fn detect_disk_type(device_name: &str) -> Result<DiskType, VolumeError> {
		let path = format!(
			"/sys/block/{}/queue/rotational",
			device_name.trim_start_matches("/dev/")
		);
		match std::fs::read_to_string(path) {
			Ok(contents) => match contents.trim() {
				"0" => Ok(DiskType::SSD),
				"1" => Ok(DiskType::HDD),
				_ => Ok(DiskType::Unknown),
			},
			Err(_) => Ok(DiskType::Unknown),
		}
	}

	fn is_volume_readonly(mount_point: &std::path::Path) -> Result<bool, VolumeError> {
		let output = Command::new("findmnt")
			.args([
				"--noheadings",
				"--output",
				"OPTIONS",
				mount_point.to_str().unwrap(),
			])
			.output()
			.map_err(|e| VolumeError::Platform(format!("Failed to run findmnt: {}", e)))?;

		let options = String::from_utf8_lossy(&output.stdout);
		Ok(options.contains("ro,") || options.contains(",ro") || options.contains("ro "))
	}

	pub async fn unmount_volume(path: &std::path::Path) -> Result<(), VolumeError> {
		// Try regular unmount first
		let result = tokio::process::Command::new("umount")
			.arg(path)
			.output()
			.await;

		match result {
			Ok(output) if output.status.success() => Ok(()),
			_ => {
				// If regular unmount fails, try lazy unmount
				let lazy_result = tokio::process::Command::new("umount")
					.args(["-l", path.to_str().unwrap()])
					.output()
					.await
					.map_err(|e| VolumeError::Platform(format!("Lazy unmount failed: {}", e)))?;

				if lazy_result.status.success() {
					Ok(())
				} else {
					Err(VolumeError::Platform(format!(
						"Failed to unmount volume: {}",
						String::from_utf8_lossy(&lazy_result.stderr)
					)))
				}
			}
		}
	}
}



#[cfg(any(target_os = "ios", target_os = "android"))]
pub mod mobile {
	use super::*;

	pub async fn get_volumes() -> Result<Vec<Volume>, VolumeError> {
		// Mobile platforms don't have mountable volumes
		Ok(Vec::new())
	}

	pub async fn unmount_volume(_path: &std::path::Path) -> Result<(), VolumeError> {
		Err(VolumeError::Platform(
			"Volumes not supported on mobile platforms".to_string(),
		))
	}
}
