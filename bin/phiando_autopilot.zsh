#!/bin/zsh
set -Eeuo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
BASE="$HOME/ANGELADOLORES"; BIN="$BASE/bin"; TOOLS="$BASE/tools"; LOGS="$BASE/logs"
ROOT="$BASE/channel/@HellinAssTV"
UPLOAD="$TOOLS/youtube_uploader.py"
PYTHON=""
for p in "$BASE/venv/bin/python3" "$(command -v python3)"; do [ -x "$p" ] && PYTHON="$p" && break; done
log(){ printf "%s %s\n" "[$(date -u +%Y-%m-%dT%H:%M:%SZ)]" "$*" | tee -a "$LOGS/autopilot.log"; }

# parse helper from UPLOAD_KIT
meta_from_kit(){ # $1 kitpath  -> prints title<TAB>desc<TAB>tags
  local kit="$1" title desc tags
  title="$(awk -F'**' '/^\*\*Title:/{print $3; exit}' "$kit" 2>/dev/null | sed 's/\r$//' )"
  desc="$(awk '/^\*\*Description:/{flag=1;next}/^$$/{if(flag){exit}}flag' "$kit" 2>/dev/null)"
  tags="$(awk -F': ' '/^\*\*Tags \(comma-separated\)\:/{print $2; exit}' "$kit" 2>/dev/null | sed 's/, */,/g')"
  printf "%s\t%s\t%s" "${title:-Untitled}" "${desc:-}" "${tags:-}"
}

run_once(){
  if [ ! -f "$BASE/secret/client_secret.json" ]; then
    log "[SKIP] Missing ~/ANGELADOLORES/secret/client_secret.json (create OAuth client in Google Cloud)."
    return 0
  fi
  for d in "$BASE"/publish/*(/N); do
    [ -d "$d" ] || continue
    KIT="$d"/UPLOAD_KIT_*.md
    [ -f $KIT ] || { log "[WARN] No UPLOAD_KIT in $d"; continue; }

    # MAIN
    mvid="$d"/.main_uploaded
    mfile=($d/*_main_1080p.mp4(N))
    if [ -f "$mfile" ] && [ ! -s "$mvid" ]; then
      read -r TITLE DESC TAGS <<<"$(meta_from_kit "$KIT" | tr '\t' ' ')"
      log "[MAIN] Uploading: $mfile"
      VID="$("$PYTHON" "$UPLOAD" --file "$mfile" --title "$TITLE" --description "$DESC" --tags "$TAGS" --privacy "unlisted" 2>&1 | tee -a "$LOGS/autopilot.log" | awk -F'=' '/\[OK\] videoId=/{print $2}' | tail -n1)"
      [ -n "$VID" ] && echo "$VID" > "$mvid" && log "[MAIN] Uploaded: $VID" || log "[MAIN] FAILED."
    fi

    # SHORTS
    svid="$d"/.shorts_uploaded
    sfile=($d/*_shorts_1080x1920.mp4(N))
    if [ -f "$sfile" ] && [ ! -s "$svid" ]; then
      STITLE="$(awk -F'**' '/^## SHORTS/{flag=1} flag && /^\*\*Title:/{print $3; exit}' "$KIT" 2>/dev/null)"
      SDESC="$(awk 'flag && /^\*\*Description:/{getline; while(length($0)>0){print; getline}} /^## SHORTS/{flag=1}' "$KIT" 2>/dev/null)"
      log "[SHORTS] Uploading: $sfile"
      SVID="$("$PYTHON" "$UPLOAD" --file "$sfile" --title "${STITLE:-Shorts}" --description "${SDESC:-Watch the full episode.}" --tags "$TAGS" --privacy "unlisted" 2>&1 | tee -a "$LOGS/autopilot.log" | awk -F'=' '/\[OK\] videoId=/{print $2}' | tail -n1)"
      [ -n "$SVID" ] && echo "$SVID" > "$svid" && log "[SHORTS] Uploaded: $SVID" || log "[SHORTS] FAILED."
    fi
  done
}

case "${1:-run}" in
  run) run_once ;;
  now) run_once ;;
  *) echo "usage: phiando_autopilot.zsh {run|now}" ;;
esac
