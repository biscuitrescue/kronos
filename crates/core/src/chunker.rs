use anyhow::Result;
use std::io::Read;

pub trait Chunker {
    fn chunk<R: Read>(&self, reader: R) -> Result<Vec<Vec<u8>>>;
}

pub struct FixedSizeChunker {
    chunk_size: usize,
}

impl FixedSizeChunker {
    pub fn new(chunk_size: usize) -> Self {
        Self { chunk_size }
    }
}

impl Chunker for FixedSizeChunker {
    fn chunk<R: Read>(&self, mut reader: R) -> Result<Vec<Vec<u8>>> {
        let mut chunks = Vec::new();
        let mut buffer = vec![0; self.chunk_size];

        loop {
            let bytes_read = reader.read(&mut buffer)?;
            if bytes_read == 0 {
                break;
            }
            chunks.push(buffer[..bytes_read].to_vec());
        }

        Ok(chunks)
    }
}
