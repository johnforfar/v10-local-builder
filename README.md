# V10 Hardware App Building Studio

A cutting-edge, hardware-aware "Vibe Coding" platform for building native NixOS applications.

## Quick Start (MacBook Pro M1)

### 1. Setup Trusted User (For Speed)
Add yourself to the trusted users list to use the pre-built AI binary cache:
```bash
echo "trusted-users = root johnny" | sudo tee -a /etc/nix/nix.conf
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

### 2. Enter the Studio Environment
```bash
nix develop
# Type 'y' to allow the numtide binary cache
```

### 3. Start "Vibe Coding" in ClaudeBox
```bash
./scripts/start-studio.sh
```
This launches a **sandboxed terminal** on port `8501`.

### 4. Build & Preview
1.  Navigate to `http://localhost:3000/builder` in your browser.
2.  The left panel provides a **ClaudeBox terminal** for natural language app building.
3.  The right panel shows a **live VNC preview** of your hardware app running in a local MicroVM.

### 5. Deploy to Bare Metal
```bash
./scripts/deploy-remote.sh <TARGET_IP> admin
```

## Maintenance
To pull the latest daily updates from the Nix AI ecosystem:
```bash
nix flake update
nix develop
```

---
*For a detailed look at the architecture, see [ENGINEERING.md](ENGINEERING.md).*
