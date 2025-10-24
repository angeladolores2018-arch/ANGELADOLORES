#!/bin/zsh
set -Eeuo pipefail
BASE="$HOME/ANGELADOLORES"; HANDLE="@HellinAssTV"; ROOT="$BASE/channel/$HANDLE"
META="$ROOT/metadata"; DOCS="$ROOT/docs"; CAPS="$ROOT/captions"
miss=0
for n in {1..15}; do ep=$(printf "S01E%02d" $n)
  for f in "${DOCS}/${ep}_script_en.md" \
           "${META}/${ep}_title_variants_en.txt" \
           "${META}/${ep}_description_en.txt" \
           "${META}/${ep}_tags_en.txt" \
           "${META}/${ep}_chapters_en.txt" \
           "${META}/${ep}_SHORTS_title_en.txt" \
           "${META}/${ep}_SHORTS_description_en.txt" \
           "${META}/${ep}_thumbnail_lines_en.txt" \
           "${META}/${ep}_pinned_comment_en.txt" \
           "${CAPS}/${ep}_template_en.srt"
  do
    [ -s "$f" ] || { echo "[MISS] $f"; miss=1; }
  done
done
[ $miss -eq 0 ] && echo "[OK] All files present." || (echo "[!] Missing items above."; exit 1)
