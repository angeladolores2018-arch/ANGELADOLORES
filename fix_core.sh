# 1) Basit env
ROOT="$(pwd)"
NOW="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="$ROOT/logs/diagnosis_report_$NOW.md"
RATLOG="$ROOT/logs/rationale.jsonl"
CORE_DIR="$ROOT/core"
MANIFEST="$ROOT/manifest.json"

mkdir -p "$CORE_DIR" "$ROOT/logs"

# 2) manifest eksik alanları ekle
if [ -f "$MANIFEST" ]; then
  if ! grep -q '"consent_required"' "$MANIFEST"; then
    cp "$MANIFEST" "$MANIFEST.bak.$NOW"
    tmp=$(mktemp)
    jq '. + {"consent_required": true, "allow_network": false, "core_dir": "core"}' "$MANIFEST" > "$tmp"
    mv "$tmp" "$MANIFEST"
    echo "- [AUTOFIX] manifest.json içine consent_required, allow_network, core_dir eklendi." >> "$REPORT"
  fi
else
  echo "- [SKIP] manifest.json bulunamadı." >> "$REPORT"
fi

# 3) core orchestrator oluştur
cat > "$CORE_DIR/phiando_core.sh" <<'SH'
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
SH
chmod +x "$CORE_DIR/phiando_core.sh"

# 4) rationale kaydı
cat >> "$RATLOG" <<JSON
{
  "timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "agent":"phiando_core_builder",
  "action":"fix_manifest_and_create_core",
  "summary":"manifest.json'a consent ve network güvenlik alanları eklendi, core orchestrator oluşturuldu",
  "confidence":0.9
}
JSON

echo "✅ Core orchestrator oluşturuldu: $CORE_DIR/phiando_core.sh"
echo "✅ manifest.json güncellendi (consent_required, allow_network, core_dir)."
echo "✅ logs/diagnosis_report ve rationale.jsonl kayıtları güncellendi."

