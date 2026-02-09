use anyhow::{Context, Result};
use std::fs;
use std::path::{Path, PathBuf};

pub trait Storage {
    fn write(&self, hash: &[u8; 32], data: &[u8]) -> Result<()>;
    fn read(&self, hash: &[u8; 32]) -> Result<Vec<u8>>;
}

pub struct FileStorage {
    root_path: PathBuf,
}

impl FileStorage {
    pub fn new<P: AsRef<Path>>(root_path: P) -> Self {
        Self {
            root_path: root_path.as_ref().to_path_buf(),
        }
    }

    fn get_path(&self, hash: &[u8; 32]) -> PathBuf {
        let hex_hash = hex::encode(hash);
        self.root_path.join(&hex_hash[0..2]).join(&hex_hash[2..])
    }
}

impl Storage for FileStorage {
    fn write(&self, hash: &[u8; 32], data: &[u8]) -> Result<()> {
        let path = self.get_path(hash);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).context("Failed to create storage directory")?;
        }
        if !path.exists() {
             fs::write(&path, data).context("Failed to write chunk")?;
        }
        Ok(())
    }

    fn read(&self, hash: &[u8; 32]) -> Result<Vec<u8>> {
        let path = self.get_path(hash);
        fs::read(&path).context("Failed to read chunk")
    }
}
