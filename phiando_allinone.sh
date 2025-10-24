#!/usr/bin/env bash
# ===============================================================
# PhiANDO All-in-One Tek Tık Kurulum ve Cleanup
# ===============================================================

set -e

BASE_DIR="$HOME/ANGELADOLORES"
CORE_DIR="$BASE_DIR/core"
PUBLISH_DIR="$BASE_DIR/publish"
LOGS_DIR="$CORE_DIR/logs"

# LOCAL ZIP TEST İÇİN (daha sonra gerçek URL ile değiştirebilirsin)
LOCAL_ZIP="$BASE_DIR/phiando_core_bundle.zip"

echo "🛠 PhiANDO All-in-One Kurulum Başlatılıyor..."

# 1) Gerekli dizinleri oluştur
mkdir -p "$CORE_DIR" "$PUBLISH_DIR" "$LOGS_DIR"

# 2) Zip aç (lokal veya indirme)
if [ -f "$LOCAL_ZIP" ]; then
    echo "📂 Lokal zip açılıyor..."
    unzip -o "$LOCAL_ZIP" -d "$CORE_DIR"
else
    echo "⚠️ Zip bulunamadı: $LOCAL_ZIP"
fi

# 3) Çalıştırılabilir yap
chmod +x "$CORE_DIR"/*.sh

# 4) Fix core çalıştır
if [ -f "$CORE_DIR/fix_core.sh" ]; then
    echo "🔧 fix_core.sh çalıştırılıyor..."
    bash "$CORE_DIR/fix_core.sh"
fi

# 5) Smoke test çalıştır
if [ -f "$CORE_DIR/phiando_smoketest.sh" ]; then
    echo "⚡ phiando_smoketest.sh çalıştırılıyor..."
    bash "$CORE_DIR/phiando_smoketest.sh"
fi

# 6) Deep Memory Sync (otomatik)
if [ -f "$CORE_DIR/phiando_active_memory.sh" ]; then
    echo "🧠 Deep Memory Sync başlatılıyor..."
    bash "$CORE_DIR/phiando_active_memory.sh"
fi

# 7) Gereksiz dosyaları temizle
echo "🧹 Geçici ve gereksiz dosyalar temizleniyor..."
find "$CORE_DIR" -name "*.tmp" -delete

# 8) Özet
echo "======================================================"
echo "✅ PhiANDO All-in-One Kurulum ve Cleanup tamamlandı."
echo "📂 Core dizin: $CORE_DIR"
echo "📂 Publish dizin: $PUBLISH_DIR"
echo "📄 Active hafıza: $LOGS_DIR/active_memory.json"
echo "======================================================"

