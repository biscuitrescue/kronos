use std::{path::PathBuf, sync::atomic::AtomicBool};

#[allow(unused)]
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

pub struct StateStore {
    pub config: Config,
    pub merkle: MerkleTree,
    pub hasher_pool: Blake3Pool,
    pub wal: WriteAheadLog,
    pub snap_idx: SnapIndex,
    pub cache: ChunkCache,
    pub log_clock: usize,
    pub is_mounted: AtomicBool,
}

pub struct MerkleTree {}
pub struct Blake3Pool {}
pub struct WriteAheadLog {}
pub struct SnapIndex {}
pub struct ChunkCache {}
