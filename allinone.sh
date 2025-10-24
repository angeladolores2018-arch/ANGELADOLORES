#!/bin/bash

# ===========================
# All-in-One Tek Tık Kurulum
# ===========================

BASE_DIR="/Users/azomazo/ANGELADOLORES"
VENV_DIR="$BASE_DIR/venv"

echo "🔹 Python venv aktive ediliyor veya oluşturuluyor..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

echo "🔹 Python paketleri yükleniyor..."
pip install --upgrade pip
pip install cairosvg

echo "🔹 Homebrew ve Cairo kontrolü..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew bulunamadı. Lütfen manuel kur."
else
    if ! brew list cairo &> /dev/null; then
        echo "Cairo bulunamadı, yüklüyor..."
        brew install cairo
    else
        echo "Cairo zaten yüklü."
    fi
fi

echo "🔹 Dizinler kontrol ediliyor..."
[ -d "$BASE_DIR/core" ] && echo "✅ core dizini bulundu" || echo "⚠️ core dizini yok"
[ -d "$BASE_DIR/publish" ] && echo "✅ publish dizini bulundu" || echo "⚠️ publish dizini yok"

echo "🔹 Core scriptleri kontrol ediliyor..."
[ -f "$BASE_DIR/core/fix_core.sh" ] && echo "✅ fix_core.sh bulundu" || echo "⚠️ fix_core.sh eksik"
[ -f "$BASE_DIR/core/phiando_smoketest.sh" ] && echo "✅ phiando_smoketest.sh bulundu" || echo "⚠️ phiando_smoketest.sh eksik"
[ -f "$BASE_DIR/core/deep_memory_sync.sh" ] && echo "✅ deep_memory_sync.sh bulundu" || echo "⚠️ deep_memory_sync.sh eksik"

echo "======================================================"
echo "🧠 PhiANDO Aktif Hafıza Güncellendi"
echo "📄 $BASE_DIR/core/logs/active_memory.json"
echo "======================================================"

echo "================ PhiANDO Smoke Test ================="
cd "$BASE_DIR"
LOG_FILE="$BASE_DIR/logs/memory.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
echo ">> Dry-run başlatılıyor..."
bash "$BASE_DIR/core/phiando_smoketest.sh" || echo "⚠️ Smoke test hata verdi"
echo "======================================================"
echo "✅ Smoke & Dry Test tamamlandı."
echo "📄 JSON log: $LOG_FILE"
echo "======================================================"

echo "🔹 SVG → PNG dönüşümü..."
SVG_FILE="$BASE_DIR/publish/cover.svg"
PNG_FILE="$BASE_DIR/publish/cover.png"
if [ -f "$SVG_FILE" ]; then
    python3 - <<PY
from cairosvg import svg2png
svg2png(url="$SVG_FILE", write_to="$PNG_FILE")
print("✅ $SVG_FILE → $PNG_FILE dönüştürüldü")
PY
else
    echo "⚠️ $SVG_FILE bulunamadı"
fi

echo "======================================================"
echo "🎉 All-in-One Tek Tık Tamamlandı!"

