use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use anyhow::Result;

pub type Hash = [u8; 32];

#[derive(Serialize, Deserialize)]
pub enum Node {
    File(FileNode),
    Dir(DirNode),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileNode {
    pub chunks: Vec<Hash>,
    pub size: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirNode {
    pub children: BTreeMap<String, Hash>,
}

pub struct MerkleTree {
    // In-memory representation or connection to storage could go here.
    // For now, it's a utility for building nodes.
}

impl MerkleTree {
    pub fn new() -> Self {
        Self {}
    }

    pub fn create_file_node(chunks: Vec<Hash>, size: u64) -> FileNode {
        FileNode { chunks, size }
    }

    pub fn create_dir_node(children: BTreeMap<String, Hash>) -> DirNode {
        DirNode { children }
    }
}
