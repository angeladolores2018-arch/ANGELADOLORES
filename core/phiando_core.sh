#!/usr/bin/env zsh
set +H
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$ROOT/core/config.json"
mkdir -p "$ROOT/core" "$ROOT/logs"

if [ ! -f "$CONFIG" ]; then
  cat > "$CONFIG" <<JSON
{
  "consent_required": true,
  "allow_network": false,
  "workers_dir": "core/workers",
  "cells_dir": "core/cells",
  "eggs_dir": "publish"
}
JSON
fi

consent_prompt() {
  local ans
  echo "PhiANDO: Yayın için onay veriyor musun? (evet/hayır)"
  read -r ans
  [[ "$ans" = "evet" || "$ans" = "yes" ]] || { echo "İptal edildi."; exit 1; }
}

case "${1:-}" in
  render)
    consent_prompt
    echo "Render pipeline başlatılıyor..."
    # burada cinematic pipeline çağrılır
    ;;
  *)
    echo "Kullanım: phiando_core.sh render"
    ;;
esac
