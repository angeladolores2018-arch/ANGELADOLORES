#!/usr/bin/env bash
# ===============================================================
# PhiANDO PHIPKG Builder
# ===============================================================

set -e

BASE_DIR="$HOME/ANGELADOLORES"
CORE_DIR="$BASE_DIR/core"
PUBLISH_DIR="$BASE_DIR/publish"
LOGS_DIR="$CORE_DIR/logs"
OUTPUT="$BASE_DIR/phiando_bundle.phipkg"

echo "�� PhiANDO PHIPKG oluşturuluyor..."

# 1) Geçici klasör
TMPDIR=$(mktemp -d)
cp -r "$CORE_DIR" "$TMPDIR/core"
cp -r "$PUBLISH_DIR" "$TMPDIR/publish"
mkdir -p "$TMPDIR/logs"
cp "$LOGS_DIR/active_memory.json" "$TMPDIR/logs/active_memory.json" 2>/dev/null || true
cp "$BASE_DIR/manifest.json" "$TMPDIR/manifest.json" 2>/dev/null || true

# 2) PHIPKG oluştur
cd "$TMPDIR"
zip -r "$OUTPUT" ./* >/dev/null
mv "$OUTPUT" "$BASE_DIR/"

# 3) Cleanup
rm -rf "$TMPDIR"

echo "✅ PhiANDO PHIPKG hazır: $OUTPUT"

