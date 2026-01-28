# Engineering Specification: V10 Hardware App Building Studio

## Objective
To build a high-fidelity, hardware-aware "Vibe Coding" platform that allows users to build native Linux/NixOS applications with a real-time preview, transitioning seamlessly from local M1 Mac environments to Bare Metal GPU production on OpenxAI's XnodeOS.

## The Evolution from Miniapp-Factory
The previous `miniapp-factory` architecture was designed for small, stateless Next.js web applications. While effective for Farcaster miniapps, it lacked the system-level depth required for hardware interactivity (USB, GPU drivers, GPIO).

### Why We Moved to V10 Local:
1.  **System-Level Awareness:** Hardware apps require NixOS configuration, not just application code. V10 generates Nix Flakes that define the entire operating system environment.
2.  **High-Fidelity Preview:** Using `microvm.nix` and `vfkit`, we can boot a Linux kernel on macOS in sub-second time. This provides a true "digital twin" of the production environment.
3.  **Local-First AI:** By leveraging local Ollama instances (DeepSeek-R1, Qwen3-Coder), we achieve bare-metal reasoning speeds without the latency or cost of cloud LLMs.

## Technical Architecture: The "Studio Mode" (Browser-Based)

To achieve the "Google AI Studio" side-by-side experience, V10 implements a **Native-to-Web Bridge**:

### 1. Unified Interface
The frontend is a Next.js application that provides:
- **Chat Panel (Left):** Real-time interaction with DeepSeek-R1 via Aider.
- **MicroVM Preview (Right):** A high-fidelity rendering of the native Linux desktop.

### 2. VNC-in-Browser Streaming
Since MicroVMs run native Linux, we stream the desktop view using:
- **WayVNC:** A VNC server running inside the MicroVM (configured via `rigup.nix`).
- **Websockify:** Bridges the VM's VNC port to a browser-compatible WebSocket.
- **noVNC:** A JavaScript VNC client embedded in the Next.js preview component.

### 3. The "Browser-to-Hardware" Pipeline
1. **User Chat:** "Build a desktop app that controls my USB thermal camera."
2. **AI Action:** AI edits the `flake.nix` (skills: `enable-usb`, `setup-web-preview`) and the app logic.
3. **Healing Loop:** `studio-test.sh` validates the build.
4. **Live Render:** The MicroVM boots, `wayvnc` starts, and the user sees the **native Linux app window** appear in their browser panel instantly.

## Deployment Pipeline
- **Development:** Locally on Mac M1 within an isolated Nix shell.
- **Validation:** Inside a local MicroVM to ensure driver compatibility.
- **Forge:** Atomic deployment to XnodeOS (NixOS Bare Metal) via `nixos-rebuild switch`.

## Ongoing Ecosystem Sync
V10 tracks the daily updates of `numtide/llm-agents.nix` and `astro/microvm.nix` to ensure it always uses the most cutting-edge AI packages and virtualization fixes.
