#!/bin/zsh
set -Eeuo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
BASE="$HOME/ANGELADOLORES"; TOOLS="$BASE/tools"
HANDLE="@HellinAssTV"; ROOT="$BASE/channel/$HANDLE"
META="$ROOT/metadata"; DOCS="$ROOT/docs"
PYTHON=""
for p in "$BASE/venv/bin/python3" "$(command -v python3)"; do [ -x "$p" ] && PYTHON="$p" && break; done
[ -n "$PYTHON" ] || { echo "[!] python3 not found"; exit 1; }

# topics map (same as plan)
typeset -A T TH R
T[S01E01]="Origins & Hustle";        TH[S01E01]="From club kid to corporate icon";           R[S01E01]="Cheap ≠ Amateur"
T[S01E02]="Supermodel Era";          TH[S01E02]="Song to brand architecture";                 R[S01E02]="Own the silhouette"
T[S01E03]="Season One";              TH[S01E03]="Vaseline filter, zero budget";               R[S01E03]="Make constraints a style"
T[S01E04]="Reading Is Fundamental";  TH[S01E04]="Wit over cruelty";                           R[S01E04]="Aim up, not down"
T[S01E05]="Snatch Game Mechanics";   TH[S01E05]="Impression vs. game theory";                 R[S01E05]="Choice beats mimicry"
T[S01E06]="Runway Criteria";         TH[S01E06]="Silhouette • Construction • Story";          R[S01E06]="Edit your outfit"
T[S01E07]="Lip Sync Dramaturgy";     TH[S01E07]="Beats, breath, camera";                      R[S01E07]="Sell the chorus, not the choreo"
T[S01E08]="Werkroom Politics";       TH[S01E08]="Producer brain";                             R[S01E08]="Confessional as chess"
T[S01E09]="RuPaul as CEO";           TH[S01E09]="Licensing, IP, merch";                       R[S01E09]="Brand > fame"
T[S01E10]="Music & Visuals";         TH[S01E10]="Singles feed seasons";                       R[S01E10]="Hook-first writing"
T[S01E11]="Global Franchise";        TH[S01E11]="Format export & culture";                    R[S01E11]="Local spice, global bones"
T[S01E12]="Post-Show Economy";       TH[S01E12]="Touring, Patreon, beauty";                   R[S01E12]="From fame to income"
T[S01E13]="Reality-TV Editing";      TH[S01E13]="Beat map & Frankenbite";                     R[S01E13]="Ethics of the cut"
T[S01E14]="Inclusivity & Controversy";TH[S01E14]="Boundaries evolve";                         R[S01E14]="Apology that works"
T[S01E15]="Legacy & Next-Gen";       TH[S01E15]="After Ru, then who?";                        R[S01E15]="Blueprint for tomorrow"

write_one(){ local ep="$1"
  [ -n "$T[$ep]" ] || { echo "[!] Unknown $ep"; return 1; }
  "$PYTHON" "$TOOLS/phiando_writer.py" "$ep" "$T[$ep]" "$TH[$ep]" "$R[$ep]"
  # regenerate Upload Kit if core CLI exists
  [ -x "$BASE/bin/phiando.zsh" ] && "$BASE/bin/phiando.zsh" publish "$ep" >/dev/null 2>&1 || true
}

case "${1:-help}" in
  S01E??) write_one "$1" ;;
  season) for n in {1..15}; do ep=$(printf "S01E%02d" $n); write_one "$ep"; done ;;
  *) echo "Usage: phiando_write.zsh {S01E01|...|season}"; exit 2 ;;
esac
