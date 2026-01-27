# KRONOS
A deterministic execution and state engine which treats FS as a derived artifact of the execution state.
Processes are not allowed to mutate FS directly. **Kronos** records explicitly ordered state transitions and stores file cocntents immutably. FS view is reconstructed from cryptographic state.

# Motivation
Traditional filesystems and container runtimes are good at isolation and snapshots, but they treat blocks as mutable entities. It doesn't answer what execution caused the current state. Previous state is lost when a block is overwritten. **Kronos** records every state transition and stores file contents immutably through chunks.

Kronos is an experiment in answering those questions by moving state ownership out of the filesystem and into a deterministic userspace engine.
