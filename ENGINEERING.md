# Engineering Specification: V10 Hardware App Building Studio

## Vision & Objective
To build a high-fidelity, hardware-aware **"Vibe Coding"** platform that allows users to build native Linux/NixOS applications with a real-time preview. The platform enables a seamless transition from local M1 Mac development to massive-scale Bare Metal GPU production on the **OpenxAI Network (XnodeOS)**.

## The Evolution from Miniapp-Factory
V10 is the strategic evolution of the `miniapp-factory` architecture. While the previous generation focused on stateless Next.js web applications, V10 targets **System-Level Mastery**. 

- **Scope Expansion**: Moving from Farcaster miniapps to hardware-native blueprints (Nix Flakes).
- **Digital Twin validation**: Every build is validated in a local MicroVM that perfectly replicates the production environment.
- **Sovereignty**: Users maintain full ownership of their Nix blueprints, ensuring their apps can run on any Xnode without provider lock-in.

## Technical Architecture: The "Studio Mode" (Local)

To achieve the "Google AI Studio" experience, V10 implements a **Native-to-Web Bridge**:

### 1. Unified Interface
The frontend is integrated into the V10 Portal at `/builder`, providing:
- **Conversational Forge (Left):** A sandboxed TTY environment running **Aider** (linked to local Ollama models like GLM-4.7 for maximum sovereignty).
- **Display Mode Toggle (Right):** A specialized panel that allows switching between **Method 1 (Web-Native)** and **Method 3 (Hardware-Native)** display strategies.

### 2. TTY-to-Web Bridge
- **ttyd**: Wraps the Aider CLI and serves it as a browser-compatible terminal on port **3001**.
- **Interactive Handshake**: The terminal allows real-time natural language interaction to guide the build process.

### 3. Display Strategies: Trimodal Isolation

Based on environmental constraints (e.g., macOS chipset issues with MicroVMs), V10 supports three primary display methods:

#### Method 1: Systemd Service / Native Process (The "Nix Native" Way)
- **Best For**: Internal services, web apps, and Mac/Linux development where kernel isolation is not required.
- **Implementation**: The app is built as a Nix package and executed directly on the host (NixOS Systemd or Mac Process).
- **Liveness**: Uses **absolute path symlinks** in the project directory for instant, zero-copy visual updates during the "vibe coding" process.
- **Portal Link**: Proxies directly to the app's listening port (Port **3005**).

#### Method 2: Declarative NixOS Containers
- **Best For**: Complex stacks requiring their own network namespace or init system.
- **Implementation**: Uses `systemd-nspawn` containers defined in `configuration.nix`.

#### Method 3: MicroVM.nix (Kernel Isolation)
- **Best For**: Hardware-aware apps, untrusted code, and high-fidelity "Digital Twin" validation.
- **Implementation**: Boots a real Linux kernel via `vfkit` (Mac) or `Firecracker/QEMU` (Linux).
- **Experimental on Mac**: Bypassed by default on macOS due to chipset compatibility issues (ARM64). Streams UI via **WayVNC** and **Websockify** to Port **8502**.

### 4. Session & Workspace Management: Progressive Sovereignty

V10 employs a **Progressive Sovereignty** model to manage user sessions across anonymous and authenticated states.

- **Ephemeral Access (Phase 1)**: Anonymous users are allocated a temporary session UUID. This identity is persisted in `localStorage` (`v10_ephemeral_uuid`), allowing work to continue across refreshes without an account.
- **Multitenant Storage (Phase 2)**: Every session is isolated in its own folder: `v10-local-builder/projects/[UUID]/`. Aider and the display bridge operate exclusively within this directory.
- **Dynamic Handshake**: The Portal discovers the active workspace identity via a **Discovery Endpoint** (`session.json`) served by the local display bridge. This ensures perfect synchronization between the frontend and the local filesystem.
- **Sovereign Transition (Phase 3)**: Upon connecting a wallet, the user can "claim" their session. This connects the project files to their permanent on-chain identity, enabling global persistence across the OpenxAI Network.
- **Persistence by Default**: All session metadata is stored in browser cache or local disk. Work is only discarded via an explicit **"Hard Reset"** operation.

### 5. The "Instant Reality" Pipeline
1. **Vibe Input**: User: *"Build a 3D GPU monitor."*
2. **AI Action**: Aider edits the project files in the isolated UUID folder.
3. **Healing Loop**: `studio-test.sh` validates the build and refreshes the project manifest.
4. **Live Render**: The Portal detects the updated timestamp in `manifest.json` and instantly refreshes the preview iframe, delivering the latest visual result in real-time.

## Deployment & Scaling Strategy

### 1. The Scaling Roadmap (Local vs. Grid)
To support 1000's of simultaneous users without overwhelming bare-metal hardware, V10 employs a **Trimodal Isolation Strategy**:

- **Tier 1: Browser-Native (Isolates)**: For simple web apps/games, the blueprint is executed in **WASM (WebAssembly)** or **V8 Isolates** directly in the user's browser. This consumes ZERO server CPU and provides instant feedback.
- **Tier 2: High-Density MicroVMs (Firecracker)**: On bare-metal Xnodes, we use **Firecracker MicroVMs** (the same technology powering AWS Lambda). These VMs have sub-second boot times and consume only ~5MB of RAM per instance, allowing 100+ environments on a single server.
- **Tier 3: Dedicated Hardware (GPU Forge)**: For intensive AI/3D tasks, the user is assigned a dedicated Xnode GPU partition via the **Sovereign Grid** orchestrator.

### 2. Immutable Blueprints
Every project is encapsulated as a pure **Nix Flake**. This ensures that the "Digital Twin" you see locally is identical to the production environment on the grid.

### 3. Grid Orchestration
The V10 Portal acts as a decentralized hub, tracking XP rewards, proof-of-build milestones, and system health across thousands of unique user environments.

## Observability
- **Centralized Logs**: All service output is redirected to the `/logs` directory.
- **Performance Monitor**: An Ollama Latency Proxy (Port 11435) tracks model reasoning speeds.
- **MicroVM Logs**: Detailed boot logs captured in `logs/microvm.log`.

## Virtualization Layer Stabilization (Journal)

### Attempt 1: Pre-built generic MicroVM runner
- **Strategy**: Use `microvm.packages.${system}.microvm-vfkit` directly from the flake.
- **Result**: FAILED. Attribute mismatch on `aarch64-darwin`. The flake structure for Apple Silicon differs from standard Linux.
- **Lesson**: Don't assume attribute parity across architectures in complex flakes.

### Attempt 2: Wrapped `microvm-run` script
- **Strategy**: Wrap the generic `microvm` package and call `microvm-run`.
- **Result**: FAILED. Binary name was actually `microvm`, and it defaulted to `/var/lib/microvms` which requires root.
- **Lesson**: The generic management tool is not suitable for local user-space development.

### Attempt 3: Native `nixosConfigurations` extraction
- **Strategy**: Define a NixOS system in `flake.nix` and extract its `.config.microvm.runner.vfkit`.
- **Result**: FAILED. Nix evaluation error: "vfkit only works on macOS (Darwin). Current host: aarch64-linux".
- **Lesson**: Defining a Linux system on a Mac host triggers platform checks that block `vfkit` evaluation inside the guest context.

### Attempt 4: Manual `vfkit` wrapper with `pkgsCross`
- **Strategy**: Manually call `vfkit` and point to `pkgs.pkgsCross.aarch64-multiplatform.linuxPackages_latest.kernel`.
- **Result**: FAILED. Recursive dependency issues (e.g., `pahole` build failing on Darwin during cross-compilation).
- **Lesson**: Cross-compiling the kernel on Mac is a "rabbit hole" of broken build-time dependencies.

### Attempt 6: Sovereign Pure Shell Bypass
- **Strategy**: Manual `vfkit` execution using `nix run nixpkgs#vfkit` and pre-compiled kernels.
- **Result**: FAILED. Error: `unknown flag: --append`.
- **Lesson**: `vfkit` requires `--kernel-cmdline` (or `-C`) for the Linux boot sequence.

### Attempt 7: Synchronous Session Reset
- **Strategy**: Change "RESET STUDIO" to "RESET APP BUILD" and force the backend to wait for UUID generation.
- **Result**: SUCCESSFUL. By switching from `subprocess.Popen` to `subprocess.run` in the native display server, the frontend reload now correctly picks up the NEW session ID because the handshake waits for the filesystem to update.
- **Lesson**: Async resets in a local-dev loop create race conditions between the browser reload and the file-writing process.

### Strategy to Fix: The "Emergency Sovereign Blueprint"
- **Memory Shielding**: Explicitly ignore `submodules` and `_archive` in VS Code to prevent 190GB memory spikes.
- **Binary Provisioning**: Bypassing local kernel compilation (which fails due to `kmod` headers) by using `nix build --no-link` on cross-compiled cached assets.
- **Rosetta 2**: Native integration via `vfkit --rosetta`, enabling x86_64 toolchain support inside the ARM64 Digital Twin.
- **Single-Evaluate Architecture**: Consolidating all studio services under a single `nix develop` context to minimize evaluation overhead.

---
*Maintained by the V10 Architecture Team*
