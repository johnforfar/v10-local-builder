#!/usr/bin/env bash
# V10 Studio Test Script: Session Reset & Preview
# This script simulates a "Hard Reset" and verifies the Native Display pipeline.

echo "--- V10 SESSION RESET TEST STARTING ---"

# 1. Generate new UUID (Skip if --no-gen is passed)
if [ "$1" == "--no-gen" ]; then
    NEW_UUID=$(cat .session_uuid | tr -d '[:space:]')
    echo "[1/4] Using Existing UUID (Pre-generated): [$NEW_UUID]"
else
    NEW_UUID=$(uuidgen | tr -d '[:space:]')
    echo "[1/4] Generated New UUID: [$NEW_UUID]"
    echo "$NEW_UUID" > .session_uuid
fi

# 2. Create a test default page in the project sub-folder
echo "[2/4] Creating Test Template..."
PROJECT_PATH="projects/$NEW_UUID"
mkdir -p "$PROJECT_PATH"
cat <<EOF > "$PROJECT_PATH/index.html"
<!DOCTYPE html>
<html>
<head>
    <title>V10 Test | Session Reset</title>
    <style>
        body { background: #1a1b1c; color: #3b82f6; display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: sans-serif; }
        .box { border: 2px solid #3b82f6; padding: 2rem; border-radius: 1rem; text-align: center; }
        .uuid { color: #fff; font-family: monospace; font-size: 0.8rem; margin-top: 1rem; opacity: 0.5; }
    </style>
</head>
<body>
    <div class="box">
        <h1>V10 Studio Reset Successful</h1>
        <p>Your new session is live and synchronized.</p>
        <div class="uuid">ID: $NEW_UUID</div>
    </div>
</body>
</html>
EOF

# 3. Trigger the display pipeline & Refresh Aider
echo "[3/4] Triggering Display Pipeline & Refreshing AI..."
pkill -f "aider" || true
# Use absolute path to boot-vm.sh to ensure it runs correctly
"$(dirname "$0")/boot-vm.sh"
echo "Waiting for display server to stabilize..."
sleep 6 # Wait for background linking and server binding

# 4. Verification
echo "[4/4] Verifying Accessibility..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3005/$NEW_UUID/index.html")

if [ "$HTTP_STATUS" == "200" ]; then
    echo "--- TEST SUCCESSFUL ---"
    echo "Endpoint is LIVE and returning 200 OK."
else
    echo "--- TEST FAILED ---"
    echo "Endpoint returned status: $HTTP_STATUS"
    exit 1
fi

echo "Target URL: http://localhost:3005/$NEW_UUID/index.html"
echo "Check your V10 Portal now. The preview panel should update automatically."
