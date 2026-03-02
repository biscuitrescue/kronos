use std::path::PathBuf;

pub struct Config {
    pub cache_size: u8,
    pub chunk_size: u8,
    pub abs_path: PathBuf,
    pub mount_path: PathBuf,
    pub wal_path: PathBuf,
    pub merkle_path: PathBuf,
    pub snap_path: PathBuf,
    pub store_path: PathBuf,
}
