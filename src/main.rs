#![allow(unused)]
/*
* Content-addressed store

Merkle tree

Snapshot structure

Root hash computation

Tests:

Same inputs → same root

Order stability

Serialization determinism
*/

fn hash_object<T: Serialize>(obj: &T) -> [u8; 32] {
    let bytes = postcard::to_allocvec(obj).unwrap();
    *blake3::hash(&bytes).as_bytes()
}

use rs_merkle::{MerkleProof, MerkleTree, algorithms::Sha256};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct File {
    pub path: String,
    pub permissions: u32,
    pub chunks: Vec<[u8; 32]>,
}

#[derive(Serialize, Deserialize)]
pub struct DirEntry {
    pub name: String,
    pub hash: Vec<[u8; 32]>,
}

#[derive(Serialize, Deserialize)]
pub struct DirNode {
    pub path: String,
    pub entries: Vec<DirEntry>,
}

fn main() {}
