#!/usr/bin/env bash
# ===============================================================
# PhiANDO All-in-One Test & PHIPKG Deploy
# ===============================================================

set -e

CORE_DIR="$HOME/ANGELADOLORES/core"
PUBLISH_DIR="$HOME/ANGELADOLORES/publish"
LOGS_DIR="$CORE_DIR/logs"
PHIPKG="$HOME/ANGELADOLORES/phiando_bundle.phipkg"
TEST_DIR="$HOME/PHIPKG_TEST"

mkdir -p "$LOGS_DIR" "$PUBLISH_DIR" "$TEST_DIR"

echo "🛠 PhiANDO All-in-One Test & Deploy Başlatılıyor..."

# --------------------------
# 1) Render Pipeline Testi (otomatik onaylı)
# --------------------------
echo "⚡ Render pipeline testi başlatılıyor..."
YES=evet bash "$CORE_DIR/phiando_core.sh" render

# --------------------------
# 2) PHIPKG Deploy Testi Temiz Dizinde
# --------------------------
echo "📂 PHIPKG temiz dizine deploy ediliyor..."
cp "$PHIPKG" "$TEST_DIR/"
cp "$CORE_DIR/phiando_deploy_phipkg.sh" "$TEST_DIR/"
cd "$TEST_DIR"
./phiando_deploy_phipkg.sh

# --------------------------
# 3) Deep Memory Sync
# --------------------------
echo "🧠 Deep Memory Sync başlatılıyor..."
bash "$CORE_DIR/phiando_active_memory.sh"

# --------------------------
# 4) Özet
# --------------------------
echo "======================================================"
echo "✅ PhiANDO All-in-One Test & PHIPKG Deploy Tamamlandı."
echo "📂 Core dizin: $CORE_DIR"
echo "📂 Publish dizin: $PUBLISH_DIR"
echo "📂 Test PHIPKG dizin: $TEST_DIR"
echo "📄 Active hafıza: $LOGS_DIR/active_memory.json"
echo "======================================================"

