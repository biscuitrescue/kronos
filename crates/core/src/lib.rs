use std::{path::PathBuf, sync::atomic::AtomicBool};

pub mod merkle;
pub mod config;

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
