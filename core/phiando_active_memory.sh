#!/usr/bin/env bash
# ===============================================================
# PhiANDO Active Memory Builder v1
# ===============================================================
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$BASE_DIR/core/logs"
SRC="$LOG_DIR/memory.jsonl"
OUT="$LOG_DIR/active_memory.json"

mkdir -p "$LOG_DIR"

if [ ! -f "$SRC" ]; then
  echo '{"error":"memory.jsonl bulunamadı"}' > "$OUT"
  echo "❌ memory.jsonl eksik, aktif hafıza oluşturulamadı."
  exit 1
fi

# JSON'ları birleştir, analiz et
SCAN_OK=$(grep -c '"status":"ok"' "$SRC")
SCAN_WARN=$(grep -c '"status":"warn"' "$SRC")
SCAN_FAIL=$(grep -c '"status":"fail"' "$SRC")

CORE_MISSING=$(grep -q 'phiando_core.sh bulunamadı' "$SRC" && echo true || echo false)
PUBLISH_MISSING=$(grep -q 'publish dizini eksik' "$SRC" && echo true || echo false)
LOGS_PRESENT=$(grep -q 'logs dizini bulundu' "$SRC" && echo true || echo false)

READY=false
if [ "$SCAN_FAIL" -eq 0 ] && [ "$CORE_MISSING" = false ]; then
  READY=true
fi

cat > "$OUT" <<JSON
{
  "agent": "phiando_memory_builder_v1",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary": {
    "scan_ok": $SCAN_OK,
    "scan_warn": $SCAN_WARN,
    "scan_fail": $SCAN_FAIL
  },
  "findings": {
    "core_orchestrator_missing": $CORE_MISSING,
    "publish_dir_missing": $PUBLISH_MISSING,
    "logs_dir_present": $LOGS_PRESENT
  },
  "system_ready": $READY,
  "memory_source": "$SRC",
  "phiando_ref": "PhiANDO Deep Memory Layer v1"
}
JSON

echo "======================================================"
echo "🧠 PhiANDO Aktif Hafıza Güncellendi"
echo "📄 $OUT"
echo "======================================================"

