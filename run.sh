#!/bin/bash
# Startup script for Kids Arcade (Godot 4)

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find Godot
GODOT=""
for candidate in \
    "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" \
    "/Applications/Godot.app/Contents/MacOS/Godot" \
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
    if [ -x "$candidate" ]; then
        GODOT="$candidate"
        break
    fi
done

if [ -z "$GODOT" ]; then
    echo "Godot not found. Download from https://godotengine.org/download"
    exit 1
fi

echo "Launching Kids Arcade..."

# Launch Godot editor in background
"$GODOT" --path "$PROJECT_DIR" &
GODOT_PID=$!

# Wait until the Debug menu exists, then click Run Project
echo "Waiting for Godot editor to load..."
for i in $(seq 1 30); do
    sleep 2
    RESULT=$(osascript 2>/dev/null <<'EOF'
tell application "Godot" to activate
delay 0.3
tell application "System Events"
    tell process "Godot"
        if exists menu "Debug" of menu bar 1 then
            click menu item "Run Project" of menu "Debug" of menu bar 1
            return "ok"
        end if
    end tell
end tell
return "waiting"
EOF
)
    if [ "$RESULT" = "ok" ]; then
        echo "Game started."
        break
    fi
    echo "  attempt $i..."
done

wait $GODOT_PID
