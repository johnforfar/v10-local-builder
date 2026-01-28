#!/bin/bash

# V10 Studio Auto-Test Script

LOG_FILE="studio-build.log"

echo "V10: Running hardware app validation..." | tee $LOG_FILE

# Check Flake
nix flake check --extra-experimental-features "nix-command flakes" 2>> $LOG_FILE
if [ $? -ne 0 ]; then
    echo "--- FLAKE SYNTAX ERROR ---" | tee -a $LOG_FILE
    exit 1
fi

# Build for local Mac MicroVM (vfkit) or target Bare Metal
# Defaulting to check if microvm derivation exists
nix build .#microvm --extra-experimental-features "nix-command flakes" 2>> $LOG_FILE
if [ $? -ne 0 ]; then
    echo "--- NIX BUILD FAILED ---" | tee -a $LOG_FILE
    exit 1
fi

echo "--- VALIDATION SUCCESSFUL ---" | tee -a $LOG_FILE
exit 0
