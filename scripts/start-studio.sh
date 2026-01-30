#!/usr/bin/env bash
# Optimized V10 Studio: Aider + Local Ollama (GLM-4.7-Flash)

export OLLAMA_API_BASE="http://localhost:11434"
export PYTHONPATH=""

echo "Launching V10 Hardware Studio..."
echo "Model: Ollama / GLM-4.7-Flash"
echo "Bridge: ttyd on port 3001"

# Start Native Display Server (Method 1) immediately as a background service
echo "Native: Initializing default HTML preview (Port 3005)..."
./scripts/start-app-native.sh > /dev/null 2>&1 &

# Discover active project directory
SESSION_UUID=$(cat .session_uuid 2>/dev/null | tr -d '[:space:]')
if [ -z "$SESSION_UUID" ]; then SESSION_UUID="local-dev"; fi
PROJECT_PATH="projects/$SESSION_UUID"
mkdir -p "$PROJECT_PATH"

# Symlink instructions to the project folder for Aider's context
ln -sf ../../.aider.instructions.md "$PROJECT_PATH/.aider.instructions.md"

# Wrap Aider in ttyd with an entrypoint that follows the LATEST project UUID.
# This ensures that even if you reset the studio, the terminal will automatically
# transition to the new project folder on the next command or refresh.
echo "Aider: Orchestrating dynamic workspace transition..."
ttyd -p 3001 -W -t fontSize=14 -t theme='{"background":"#000000", "foreground":"#ffffff", "cursor":"#2563eb"}' \
    sh -c '
        while true; do
            UUID=$(cat .session_uuid 2>/dev/null | tr -d "[:space:]")
            # FALLBACK logic: If .session_uuid is local-dev, but browser has a different one,
            # we must favor the browser truth. For now, we ensure the backend refreshes properly.
            if [ -z "$UUID" ]; then UUID="local-dev"; fi
            PROJECT_PATH="projects/$UUID"
            mkdir -p "$PROJECT_PATH"
            ln -sf ../../.aider.instructions.md "$PROJECT_PATH/.aider.instructions.md"
            echo "--- V10 SESSION ACTIVE: $UUID ---"
            # Refresh display bridge to align symlinks and session.json with current UUID
            "$(pwd)/../../scripts/start-app-native.sh" > /dev/null 2>&1 &
            cd "$PROJECT_PATH" && aider --model "ollama/glm-4.7-flash:q4_K_M" --map-tokens 0 --no-stream --edit-format whole --no-auto-commits --yes-always --auto-test --test-cmd "../../scripts/boot-vm.sh"
            echo "--- SESSION ENDED or RESET DETECTED ---"
            cd ../..
            sleep 1
        done
    '
