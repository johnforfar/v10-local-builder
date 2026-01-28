#!/bin/bash

# V10 Local-to-Remote Deployment Pipeline
# Pushes the validated Nix Flake to the Bare Metal GPU Cloud (OpenxAI)

TARGET_IP="${1:-your_bare_metal_ip}"
TARGET_USER="${2:-admin}"

echo "Deploying V10 Hardware App to Remote NixOS Bare Metal..."

# 1. Ensure the local build passes first
./scripts/studio-test.sh
if [ $? -ne 0 ]; then
    echo "Deployment aborted: Local validation failed."
    exit 1
fi

# 2. Push the flake and trigger remote rebuild
# This assumes the target is a NixOS machine with flakes enabled
nixos-rebuild switch \
    --flake .#bare-metal-app \
    --target-host "${TARGET_USER}@${TARGET_IP}" \
    --use-remote-sudo \
    --fast

if [ $? -eq 0 ]; then
    echo "Deployment successful. App is live on ${TARGET_IP}"
else
    echo "Remote deployment failed. Check logs for target machine."
    exit 1
fi
