#!/usr/bin/env bash
# V10 Native Display Runner (Method 1) - Secure, Precise & Bulletproof
# Bypasses MicroVM for local web-only development.

PORT=3005
# CRITICAL: Strip any newlines or whitespace from the UUID
SESSION_UUID=$(cat .session_uuid 2>/dev/null | tr -d '[:space:]')
if [ -z "$SESSION_UUID" ]; then SESSION_UUID="local-dev"; fi

# Discovery logic: Use projects subfolder if running from root
# CRITICAL: Always use the absolute path to the v10-local-builder directory
# to avoid pathing issues when scripts are launched from different locations.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECTS_DIR="$BASE_DIR/projects"
PROJECT_PATH="$PROJECTS_DIR/$SESSION_UUID"
PREVIEW_ROOT="/tmp/v10-native"

echo "--- V10 NATIVE DISPLAY INITIALIZED ---"
echo "Method: 1 (Systemd-Equivalent / Process Isolation)"
echo "Base Dir: $BASE_DIR"
echo "Project Path: $PROJECT_PATH"
echo "Session UUID: [$SESSION_UUID]"

# Ensure the local project directory exists
mkdir -p "$PROJECT_PATH"

# CLEAN SLATE: Recreate the entire preview root to eliminate stale session paths
rm -rf "$PREVIEW_ROOT"
mkdir -p "$PREVIEW_ROOT"
# SECURITY & SPEED: Link the specific project folder to the preview root
# We use the absolute path to the project folder
ln -sfn "$PROJECT_PATH" "$PREVIEW_ROOT/$SESSION_UUID"
ln -sfn "$PROJECT_PATH" "$PREVIEW_ROOT/local-dev"

# Generate a global session discovery file
# CRITICAL: This is the source of truth for the Portal's identity handshake.
function update_session_discovery() {
    cat <<EOF > "$PREVIEW_ROOT/session.json"
{
  "sessionUuid": "$SESSION_UUID",
  "updated": "$(date +%s%N)"
}
EOF
}

update_session_discovery

# CRITICAL: Always generate manifest.json even if index.html exists
function update_manifest() {
    LAST_UPDATE=$(date +%s%N)
    cat <<EOF > "$PROJECT_PATH/manifest.json"
{
  "session": "$SESSION_UUID",
  "updated": "$LAST_UPDATE",
  "files": [
$(ls -p "$PROJECT_PATH" | grep -v / | sed 's/^\(.*\)$/    "\1"/' | paste -sd "," -)
  ]
}
EOF
}

update_manifest

# Fallback index at root for heartbeat
echo "<h1>V10 Native Hub</h1><p>Active Session: $SESSION_UUID</p>" > "$PREVIEW_ROOT/index.html"

# BULLETPROOF KILL: Ensure no other process is holding the port
echo "Cleaning port $PORT..."
lsof -ti :$PORT | xargs kill -9 > /dev/null 2>&1 || true
pkill -9 -f "python3 -m http.server $PORT" > /dev/null 2>&1 || true
pkill -9 -f "python3 server.py" > /dev/null 2>&1 || true
pkill -9 -f "server.py" > /dev/null 2>&1 || true
sleep 2

# CORS HACK: Use a simple Python server that includes CORS headers
# Since we are in a dev environment, we can use a small wrapper.
cat <<EOF > "$PREVIEW_ROOT/server.py"
import http.server
import socketserver
import sys
import subprocess
import os

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        if self.path == '/reset':
            # TRIGGER BACKEND RESET: Run the test-session-reset.sh script
            # We assume the script is in the scripts folder relative to the project root.
            try:
                # Calculate scripts path relative to this /tmp location is hard, 
                # so we use the absolute path we injected.
                script_path = os.path.join("$SCRIPT_DIR", "test-session-reset.sh")
                # Wait for the script to generate the new UUID before responding
                # This ensures the filesystem is updated BEFORE the frontend reloads.
                # We only run the generation part synchronously, the rest can be async.
                
                # Extract UUID generation logic to be fast and sync
                new_uuid = subprocess.check_output(["uuidgen"]).decode().strip()
                with open(os.path.join("$BASE_DIR", ".session_uuid"), "w") as f:
                    f.write(new_uuid)
                
                # Now trigger the full cleanup/reboot in the background
                subprocess.Popen([script_path, "--no-gen"], cwd="$BASE_DIR", start_new_session=True)
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'{"status":"reset_triggered"}')
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404)
            self.end_headers()

port = $PORT
socketserver.TCPServer.allow_reuse_address = True
try:
    with socketserver.TCPServer(("", port), CORSRequestHandler) as httpd:
        print(f"Serving at port {port}")
        httpd.serve_forever()
except Exception as e:
    print(f"Error starting server: {e}", file=sys.stderr)
    sys.exit(1)
EOF

echo "Starting Native Display Server at $PREVIEW_ROOT (Port $PORT) with CORS..."
cd "$PREVIEW_ROOT"
# Use python3 if available, otherwise fallback to python
PYTHON_BIN=$(command -v python3 || command -v python)
nohup $PYTHON_BIN server.py > server.log 2>&1 &
sleep 2
echo "Server process $(pgrep -f 'server.py' | tail -n 1) is now active."
# Output the last few lines of the server log to verify it started
tail -n 5 server.log
