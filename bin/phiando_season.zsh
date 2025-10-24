#!/bin/zsh
set -Eeuo pipefail
BASE="$HOME/ANGELADOLORES"; BIN="$BASE/bin"
# 1) write all
"$BIN/phiando_write.zsh" season
# 2) build all
for n in {1..15}; do ep=$(printf "S01E%02d" $n); "$BIN/phiando.zsh" build "$ep"; done
# 3) upload kits already refreshed by publish step inside write/build
echo "Season build complete. Check publish/S01E*/UPLOAD_KIT_*.md"
