#!/bin/bash
osascript >/dev/null 2>&1 <<EOF
  tell application "iTerm"
    create window with profile "lima"
  end tell
EOF

