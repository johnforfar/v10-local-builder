# Configuration for V10 Aider Hybrid Session
# Optimized for macOS M1 local dev with GLM-4.7-Flash

export OLLAMA_API_BASE="http://localhost:11434"

echo "Launching V10 Hardware App Studio Session with GLM-4.7-Flash..."

aider \
    --model "ollama_chat/glm-4.7-flash:q4_K_M" \
    --editor-model "ollama_chat/glm-4.7-flash:q4_K_M" \
    --architect \
    --gui \
    --auto-test \
    --test-cmd "./scripts/studio-test.sh" \
    --yes \
    --no-gitignore \
    --message "V10 Architect (GLM-4.7-Flash) active. I am ready to build your hardware-aware NixOS application."
