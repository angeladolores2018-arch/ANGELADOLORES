#!/usr/bin/env bash
# ===============================================================
# PhiANDO PHIPKG Auto-Deploy
# ===============================================================

set -e

BASE_DIR="$HOME/ANGELADOLORES"
CORE_DIR="$BASE_DIR/core"
PUBLISH_DIR="$BASE_DIR/publish"
LOGS_DIR="$CORE_DIR/logs"
PHIPKG_FILE="$BASE_DIR/phiando_bundle.phipkg"

echo "🛠 PhiANDO PHIPKG deploy başlatılıyor..."

# 1) PHIPKG mevcut mu?
if [ ! -f "$PHIPKG_FILE" ]; then
    echo "⚠️ PHIPKG bulunamadı: $PHIPKG_FILE"
    exit 1
fi

# 2) Geçici aç
TMPDIR=$(mktemp -d)
echo "📂 PHIPKG açılıyor..."
unzip -q -o "$PHIPKG_FILE" -d "$TMPDIR"

# 3) Core, Publish ve Logs klasörlerini taşı
mkdir -p "$CORE_DIR" "$PUBLISH_DIR" "$LOGS_DIR"
cp -r "$TMPDIR/core/"* "$CORE_DIR/"
cp -r "$TMPDIR/publish/"* "$PUBLISH_DIR/"
cp -r "$TMPDIR/logs/"* "$LOGS_DIR/" 2>/dev/null || true
cp -r "$TMPDIR/manifest.json" "$BASE_DIR/" 2>/dev/null || true

# 4) Çalıştırılabilir yap
chmod +x "$CORE_DIR"/*.sh

# 5) Fix core çalıştır
if [ -f "$CORE_DIR/fix_core.sh" ]; then
    echo "🔧 fix_core.sh çalıştırılıyor..."
    bash "$CORE_DIR/fix_core.sh"
fi

# 6) Smoke test çalıştır
if [ -f "$CORE_DIR/phiando_smoketest.sh" ]; then
    echo "⚡ phiando_smoketest.sh çalıştırılıyor..."
    bash "$CORE_DIR/phiando_smoketest.sh"
fi

# 7) Deep Memory Sync
if [ -f "$CORE_DIR/phiando_active_memory.sh" ]; then
    echo "🧠 Deep Memory Sync başlatılıyor..."
    bash "$CORE_DIR/phiando_active_memory.sh"
fi

# 8) Cleanup
echo "🧹 Geçici ve gereksiz dosyalar temizleniyor..."
rm -rf "$TMPDIR"

# 9) Özet
echo "======================================================"
echo "✅ PhiANDO PHIPKG Deploy tamamlandı."
echo "📂 Core dizin: $CORE_DIR"
echo "📂 Publish dizin: $PUBLISH_DIR"
echo "📄 Active hafıza: $LOGS_DIR/active_memory.json"
echo "======================================================"

