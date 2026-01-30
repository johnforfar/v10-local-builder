#!/usr/bin/env bash
# V10 MicroVM Lifecycle Manager: Hydra-Rosetta Edition
# This script uses the pre-verified Hydra runner but injects Rosetta 2 support.

LOG_FILE="../logs/microvm.log"
mkdir -p ../logs

echo "[$(date +%T)] System: Triggering Digital Twin boot (Hydra-Verified + Rosetta Override)..." | tee -a $LOG_FILE

# 1. Kill any existing instances
pkill -f "vfkit" || true
pkill -f "microvm" || true

# 2. OS Detection & Conditional Launch
OS_TYPE=$(uname)

if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "[$(date +%T)] System: macOS detected. Bypassing MicroVM (Method 3) to prevent chipset failure." | tee -a $LOG_FILE
    echo "[$(date +%T)] Native: Launching Method 1 Display (Port 3005)..." | tee -a $LOG_FILE
    ./scripts/start-app-native.sh >> $LOG_FILE 2>&1 &
else
    echo "[$(date +%T)] System: Linux detected. Initializing Hardware Digital Twin (Method 3)..." | tee -a $LOG_FILE
    nix run .#microvm --impure --accept-flake-config -- \
        --rosetta \
        --device virtio-fs,tag=project,path=$(pwd) >> $LOG_FILE 2>&1 &
    
    echo "[$(date +%T)] Native: Starting Method 1 Parallel Display..." | tee -a $LOG_FILE
    ./scripts/start-app-native.sh >> $LOG_FILE 2>&1 &
fi

echo "[$(date +%T)] Status: Display Pipeline ready and refreshed." | tee -a $LOG_FILE
