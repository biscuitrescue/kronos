pub struct Config {
    pub abs_path: PathBuf,
    pub mount_path: PathBuf,
    pub wal_path: PathBuf,
    pub merkle_path: PathBuf,
    pub snap_path: PathBuf,
    pub store_path: PathBuf,
    pub cache_size: usize,
    pub chunk_size: usize,
}

impl Config {
    pub fn new(abs_path: PathBuf, mount_path: PathBuf) -> Self {
        let root = abs_path.join(".kronos");
        Self {
            abs_path,
            mount_path,
            wal_path: root.join("wal"),
            merkle_path: root.join("merkle"),
            snap_path: root.join("snap"),
            store_path: root.join("store"),
            cache_size: 1024,
            chunk_size: 64 * 1024,
        }
    }
}
