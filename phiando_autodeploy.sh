#!/usr/bin/env bash
# ===============================================================
# PhiANDO Auto Deploy & Cleanup All-in-One
# ===============================================================

set -e

BASE_DIR="$HOME/ANGELADOLORES"
CORE_DIR="$BASE_DIR/core"
PUBLISH_DIR="$BASE_DIR/publish"
LOGS_DIR="$CORE_DIR/logs"
ZIP_URL="https://example.com/phiando_core_bundle.zip" # burayı kendi zip linkinle değiştir
ZIP_FILE="$BASE_DIR/phiando_bundle.zip"

echo "🛠 PhiANDO otomatik deploy başlatılıyor..."

# 1) Zip indir
echo "⬇️ Zip indiriliyor..."
curl -L "$ZIP_URL" -o "$ZIP_FILE"

# 2) Zip aç
echo "�� Zip açılıyor..."
mkdir -p "$CORE_DIR"
unzip -o "$ZIP_FILE" -d "$CORE_DIR"

# 3) Dizeleri oluştur
mkdir -p "$PUBLISH_DIR" "$LOGS_DIR"

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

# 7) Deep Memory Sync (otomatik)
if [ -f "$CORE_DIR/phiando_active_memory.sh" ]; then
  echo "🧠 Deep Memory Sync başlatılıyor..."
  bash "$CORE_DIR/phiando_active_memory.sh"
fi

# 8) Gereksiz dosyaları temizle
echo "🧹 Geçici ve gereksiz dosyalar temizleniyor..."
rm -f "$ZIP_FILE"
find "$CORE_DIR" -name "*.tmp" -delete

# 9) Özet
echo "======================================================"
echo "✅ PhiANDO otomatik deploy & cleanup tamamlandı."
echo "📂 Core dizin: $CORE_DIR"
echo "📂 Publish dizin: $PUBLISH_DIR"
echo "📄 Active hafıza: $LOGS_DIR/active_memory.json"
echo "======================================================"

