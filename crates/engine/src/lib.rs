use anyhow::{Context, Result};
use core::chunker::{Chunker, FixedSizeChunker};
use core::config::Config;
use core::merkle::{FileNode, Hash};
use core::storage::{FileStorage, Storage};
use std::fs::File;
use std::path::{Path, PathBuf};

pub struct Engine {
    config: Config,
    chunker: FixedSizeChunker,
    storage: FileStorage,
}

impl Engine {
    pub fn new(config: Config) -> Self {
        let chunker = FixedSizeChunker::new(config.chunk_size);
        let storage = FileStorage::new(&config.store_path);
        Self {
            config,
            chunker,
            storage,
        }
    }

    pub fn add_file<P: AsRef<Path>>(&self, path: P) -> Result<Hash> {
        let path = path.as_ref();
        let file = File::open(path).context("Failed to open file")?;
        let size = file.metadata()?.len();

        let chunks = self.chunker.chunk(file)?;
        let mut chunk_hashes = Vec::new();

        for chunk in chunks {
            let hash = blake3::hash(&chunk);
            let hash_bytes: [u8; 32] = hash.into();
            self.storage.write(&hash_bytes, &chunk)?;
            chunk_hashes.push(hash_bytes);
        }

        let file_node = FileNode {
            chunks: chunk_hashes,
            size,
        };

        // For now, we just return the hash of the FileNode itself (serialized)
        // In a real system, we'd store this node in a CAS too, or a specific tree structure.
        let node_bytes = bincode::serialize(&core::merkle::Node::File(file_node))
            .context("Failed to serialize file node")?;
        
        // Wait, core::merkle::Node doesn't derive Serialize/Deserialize in my previous edit? 
        // I should check core::merkle::Node. 
        // Checking... yes I added Serialize, Deserialize. 
        // But I need `bincode` dependency in `engine` or `core` to serialize it easily here, 
        // OR I can use `serde_json` or just manual hashing if I just want a hash.
        // Let's use `blake3` on the bytes for now. 
        // But to get bytes I need serialization.
        // Let's assume for now I just want to return the hash of the content (root hash of the file).
        // Since I don't have a Merkle Tree builder yet that builds a tree from chunks, 
        // I will just return the hash of the list of chunk hashes for now.
        
        // Simpler approach for skeletal implementation:
        // Hash of the file node = Hash(concatenated chunk hashes)
        let mut hasher = blake3::Hasher::new();
        for hash in &file_node.chunks {
            hasher.update(hash);
        }
        let file_hash = hasher.finalize();
        Ok(file_hash.into())
    }
}
