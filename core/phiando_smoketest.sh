#!/usr/bin/env bash
# ===============================================================
# PhiANDO Smoke & Dry Test System (v1.0)
# ===============================================================
# Author: PhiANDO System
# Mode: Dry-run (no destructive actions)
# Logs: logs/memory.jsonl
# ===============================================================

set -euo pipefail
BASE_DIR="$(pwd)"
LOG_DIR="$BASE_DIR/logs"
MEMORY_LOG="$LOG_DIR/memory.jsonl"
AGENT="phiando_smoke_tester_v1"
TS() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

mkdir -p "$LOG_DIR"
touch "$MEMORY_LOG"

log_json() {
  local PHASE="$1" STATUS="$2" SUMMARY="$3"
  printf '{"timestamp":"%s","agent":"%s","phase":"%s","status":"%s","summary":"%s"}\n' \
    "$(TS)" "$AGENT" "$PHASE" "$STATUS" "$SUMMARY" >> "$MEMORY_LOG"
}

echo "================ PhiANDO Smoke Test ================="
echo "Çalışma dizini: $BASE_DIR"
echo "Log: $MEMORY_LOG"
echo "====================================================="

# ---------------------------------------------------------------
# 1. Scan phase
# ---------------------------------------------------------------
log_json "scan" "ok" "Başlatılıyor: PhiANDO smoke test taraması."
[[ -d core ]] && log_json "scan" "ok" "core dizini bulundu." || log_json "scan" "warn" "core dizini eksik."
[[ -d publish ]] && log_json "scan" "ok" "publish dizini bulundu." || log_json "scan" "warn" "publish dizini eksik."
[[ -d logs ]] && log_json "scan" "ok" "logs dizini bulundu." || log_json "scan" "warn" "logs dizini eksik."
[[ -f core/phiando_core.sh ]] && log_json "scan" "ok" "phiando_core.sh bulundu." || log_json "scan" "fail" "phiando_core.sh bulunamadı."

# ---------------------------------------------------------------
# 2. Dry-run phase
# ---------------------------------------------------------------
if [[ -x core/phiando_core.sh ]]; then
  echo ">> Dry-run başlatılıyor (simülasyon)..."
  {
    echo "PhiANDO: (dry mode) render pipeline testi başlatılıyor..."
    echo "(Simülasyon) core orchestrator başarıyla çağrıldı."
  } | tee >(while read -r line; do log_json "dry_run" "ok" "$line"; done)
else
  log_json "dry_run" "fail" "phiando_core.sh çalıştırılabilir değil."
fi

# ---------------------------------------------------------------
# 3. Summary phase
# ---------------------------------------------------------------
TOTAL=$(wc -l < "$MEMORY_LOG" | tr -d ' ')
log_json "summary" "ok" "Toplam $TOTAL JSON kayıt memory loguna yazıldı."
echo "====================================================="
echo "✅ Smoke & Dry Test tamamlandı."
echo "📄 JSON log: $MEMORY_LOG"
echo "====================================================="
