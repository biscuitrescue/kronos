use anyhow::Result;
use clap::{Parser, Subcommand};
use core::config::Config;
use engine::Engine;
use std::env;
use std::path::PathBuf;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize the repository
    Init,
    /// Add a file to the repository
    Add {
        /// Path to the file
        path: PathBuf,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    let cwd = env::current_dir()?;
    // For now, assuming mount point is "mnt" in cwd, but it's not used yet.
    let config = Config::new(cwd.clone(), cwd.join("mnt")); 
    
    // Ensure .kronos dir exists for init, or check for it?
    // Engine initializes paths in Config but doesn't create them until needed (Storage::write).
    
    match cli.command {
        Commands::Init => {
            // Create .kronos directory and subdirectories
            let root = config.abs_path.join(".kronos");
            std::fs::create_dir_all(&config.wal_path)?;
            std::fs::create_dir_all(&config.merkle_path)?;
            std::fs::create_dir_all(&config.snap_path)?;
            std::fs::create_dir_all(&config.store_path)?;
            println!("Initialized Kronos repository at {:?}", root);
        }
        Commands::Add { path } => {
            let engine = Engine::new(config);
            match engine.add_file(path) {
                Ok(hash) => {
                    println!("Added file. Hash: {}", hex::encode(hash));
                }
                Err(e) => {
                    eprintln!("Error adding file: {:?}", e);
                }
            }
        }
    }

    Ok(())
}
