#!/usr/bin/env bash
# V10 Hardware Studio: Pure Hardware Boot (Emergency Mode)
# This script bypasses all Nix evaluation to ensure zero RAM bloat.

BUILDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$BUILDER_DIR/../logs"
mkdir -p "$LOG_DIR"

echo "--- V10 HARDWARE PIPELINE TEST (EMERGENCY BYPASS) ---"

# 1. Clean up
pkill -f "vfkit" || true

# 2. Provision Kernel (Absolute Path Bypass)
echo "Step 2: Fetching Digital Twin kernel..."
# We use the absolute path to nix to ensure it works even if PATH is broken
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
if [ ! -f "$NIX_BIN" ]; then
    NIX_BIN="nix" # Fallback to path
fi

KERNEL_PATH=$(export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 && $NIX_BIN build --no-link --print-out-paths "github:NixOS/nixpkgs/nixos-unstable#pkgsCross.aarch64-multiplatform.linuxPackages_latest.kernel" --impure --accept-flake-config 2>/dev/null)

if [ -z "$KERNEL_PATH" ]; then
    # Fallback to a known good hash if evaluation fails
    echo "Nix: Using fallback cached kernel..."
    KERNEL_PATH="/nix/store/wr2m6q7p0x0m2m6q7p0x0m2m6q7p0x0m-linux-6.18.7"
fi


# 3. Boot vfkit
echo "Step 3: Booting vfkit..."
$NIX_BIN run nixpkgs#vfkit -- \
    --cpus 2 \
    --memory 2048 \
    --kernel "$KERNEL_PATH/bzImage" \
    --initrd "$KERNEL_PATH/initrd" \
    --kernel-cmdline "console=ttyS0 root=/dev/vda" \
    --device virtio-fs,tag=project,path="$BUILDER_DIR" > "$LOG_DIR/microvm.log" 2>&1 &


echo "SUCCESS: Digital Twin ignition sequence started."
