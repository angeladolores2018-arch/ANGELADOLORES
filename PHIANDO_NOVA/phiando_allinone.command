#!/bin/zsh
echo "🌸 Starting PhiANDO_NOVA All-in-One..."
TARGET="$HOME/ANGELADOLORES/PHIANDO_NOVA"

# Check for Python
if ! command -v python3 >/dev/null 2>&1; then
  echo "⚙️ Python3 not found. Installing..."
  brew install python
fi

# Prepare environment
mkdir -p "$TARGET/core" "$TARGET/data" "$TARGET/scripts"

# Create sqlite if missing
if [ ! -f "$TARGET/data/memories.sqlite" ]; then
  echo "🧠 Creating memory database..."
  sqlite3 "$TARGET/data/memories.sqlite" "VACUUM;"
fi

# Fix phi_core.py
cat > "$TARGET/core/phi_core.py" <<'EOF'
import sqlite3, os
print('🧠 Phi Core initialized')
EOF

# Launch core
python3 "$TARGET/core/phi_core.py"

# Launch VS Code if installed
if [ -d "/Applications/Visual Studio Code.app" ]; then
  echo "💫 Opening VS Code project..."
  open -a "Visual Studio Code" "$TARGET"
else
  echo "⚠️ VS Code not found — please install later."
fi

# Start local server
echo "🚀 Starting PhiANDO local stage..."
cd "$TARGET"
python3 -m http.server 3000 >/dev/null 2>&1 &
sleep 3
open "http://localhost:3000"

echo "✅ PhiANDO_NOVA is alive ✨"

