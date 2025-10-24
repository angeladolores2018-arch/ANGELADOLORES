#!/usr/bin/env bash
# ==============================================================
# PhiANDO Deep Memory Sync Patch
# ==============================================================

MEMORY_SCRIPT="$(dirname "$0")/phiando_active_memory.sh"
if [ -f "$MEMORY_SCRIPT" ]; then
  echo "🧠 Deep Memory Sync başlatılıyor..."
  bash "$MEMORY_SCRIPT"
  echo "✅ Deep Memory senkronizasyonu tamamlandı."
else
  echo "⚠️ Deep Memory Sync atlandı: phiando_active_memory.sh bulunamadı."
fi

