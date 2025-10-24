#!/bin/zsh
set -Eeuo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

BASE="$HOME/ANGELADOLORES"
BIN="$BASE/bin"
export PATH="$BIN:/usr/bin:/bin:/usr/sbin:/sbin"
HANDLE="@HellinAssTV"
ROOT="$BASE/channel/$HANDLE"
META="$ROOT/metadata"; DOCS="$ROOT/docs"; CAPS="$ROOT/captions"
LOCK="$ROOT/CHANNEL_LOCK"
EP_DEFAULT="S01E01"

have(){ command -v "$1" >/dev/null 2>&1; }
to0x(){ local s="$(printf "%s" "$1" | tr '[:lower:]' '[:upper:]' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if   echo "$s" | grep -Eq '^0X[0-9A-F]{6}$'; then echo "$s"
  elif echo "$s" | grep -Eq '^#[0-9A-F]{6}$';  then echo "0x${s#\#}"
  elif echo "$s" | grep -Eq '^[0-9A-F]{6}$';   then echo "0x$s"
  else echo "0x0D0D0D"; fi; }
tohash(){ echo "$1" | sed -E 's/^0[Xx]/#/' ; }
cfg_get(){ # key default
  local CFG="$ROOT/phiando.config" k="$1" d="$2" l v
  [ -f "$CFG" ] || { printf "%s" "$d"; return; }
  l="$(grep -E "^[[:space:]]*${k}[[:space:]]*=" "$CFG" 2>/dev/null | tail -n1 || true)"
  if [ -n "$l" ]; then
    v="${l#*=}"; v="$(printf "%s" "$v" | sed -E 's/[[:space:]]+#.*$//; s/^[[:space:]]+|[[:space:]]+$//g')"
    v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"; printf "%s" "$v"
  else printf "%s" "$d"; fi
}
ensure_ff(){ 
  if ! have ffmpeg || ! have ffprobe; then
    mkdir -p "$BIN" && cd "$BIN"
    [ -x ./ffmpeg ]  || { echo "[*] Installing ffmpeg…";  curl -Ls -o ffmpeg.zip  "https://evermeet.cx/ffmpeg/ffmpeg-6.0.zip"  && unzip -o ffmpeg.zip  >/dev/null && chmod +x ffmpeg; }
    [ -x ./ffprobe ] || { echo "[*] Installing ffprobe…"; curl -Ls -o ffprobe.zip "https://evermeet.cx/ffmpeg/ffprobe-6.0.zip" && unzip -o ffprobe.zip >/dev/null && chmod +x ffprobe; }
    cd - >/dev/null
  fi
}

safety_doctor(){
  echo "===== PHIANDO DOCTOR ====="
  sw_vers -productVersion | awk '{print "OS:", $0}'
  sysctl -n hw.ncpu | awk '{print "CPU cores:", $0}'
  DF="$(df -H "$HOME" | awk 'NR==2{print $4}')"; echo "Free disk: $DF"
  for b in ffmpeg ffprobe say awk sed grep; do 
    if have "$b"; then echo "[OK] $b: $(command -v $b)"; else echo "[!!] $b: MISSING"; fi
  done
  have ffmpeg && ffmpeg -hide_banner -filters 2>/dev/null | awk '/drawtext|showwaves|subtitles|overlay|scale|format/{print "[OK] filter:",$2}'
  for f in "/Library/Fonts/Arial Unicode.ttf" "/System/Library/Fonts/Supplemental/Arial Unicode.ttf" "/Library/Fonts/Arial.ttf"; do
    [ -f "$f" ] && FONT="$f" && break
  done
  [ -n "$FONT" ] && echo "[OK] font: $FONT" || echo "[!!] font not found"
  echo "================================"
}

safety_smoke(){
  ensure_ff
  DEST="$BASE/smoke/SMOKE_$(date +%Y%m%d_%H%M%S)"; mkdir -p "$DEST"; cd "$DEST"
  VOICE="$(say -v "?" 2>/dev/null | awk '/^(Samantha|Ava|Victoria)/{print $1; exit}')" || VOICE=""
  if [ -n "$VOICE" ]; then
    say -o tmp.aiff -v "$VOICE" -r 180 "This is a Phiando smoke test."
    ffmpeg -nostdin -y -hide_banner -loglevel error -i tmp.aiff -ar 48000 -ac 1 smoke.wav
    rm -f tmp.aiff
  else
    ffmpeg -nostdin -y -hide_banner -loglevel error -f lavfi -t 5 -i anullsrc=cl=mono:r=48000 smoke.wav
  fi
  # colors
  BGHEX="$(to0x "$(cfg_get BRAND_BG '#0D0D0D')" )"
  ACCHEX="$(to0x "$(cfg_get BRAND_PRIMARY '#00FFC6')" )"
  SECHX="$(to0x "$(cfg_get BRAND_SECONDARY '#6C63FF')" )"
  ffmpeg -nostdin -y -hide_banner -loglevel error \
    -f lavfi -t 5 -r 30 -i "color=c=${BGHEX}:s=1280x720" -i smoke.wav \
    -filter_complex "[0:v]format=rgba[v];[1:a]asplit=2[aout][avis];[avis]showwaves=s=1280x200:mode=line:colors=${ACCHEX}|${SECHX}[wave];[v][wave]overlay=0:520[v2];[v2]drawtext=fontfile='/Library/Fonts/Arial Unicode.ttf':text='SMOKE TEST OK':x=(w-text_w)/2:y=260:fontsize=48:fontcolor=#FFFFFF[vout]" \
    -map "[vout]" -map "[aout]" -c:v libx264 -preset veryfast -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k smoke_test_720p.mp4
  DUR="$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 smoke_test_720p.mp4 || echo 0)"
  echo "Output: $DEST/smoke_test_720p.mp4 (duration: ${DUR}s)"
  open -R "$DEST" >/dev/null 2>&1 || true
}

build(){
  ensure_ff
  EP="${1:-$EP_DEFAULT}"
  OUT="$BASE/publish/$EP"; mkdir -p "$OUT"
  # Colors + durations
  BGHEX="$(to0x "$(cfg_get BRAND_BG '#0D0D0D')" )"
  ACCHEX="$(to0x "$(cfg_get BRAND_PRIMARY '#00FFC6')" )"
  SECHX="$(to0x "$(cfg_get BRAND_SECONDARY '#6C63FF')" )"
  ACCFONT="$(tohash "$ACCHEX")"; TXTCL="#FFFFFF"
  MAIN_TARGET="$(cfg_get MAIN_DURATION_TARGET_SEC '360')"; echo "$MAIN_TARGET" | grep -Eq '^[0-9]+$' || MAIN_TARGET=360
  SHORTS_TARGET="$(cfg_get SHORTS_TARGET_SEC '30')";      echo "$SHORTS_TARGET" | grep -Eq '^[0-9]+$' || SHORTS_TARGET=30
  # Fonts
  for f in "/Library/Fonts/Arial Unicode.ttf" "/System/Library/Fonts/Supplemental/Arial Unicode.ttf" "/Library/Fonts/Arial.ttf"; do [ -f "$f" ] && FONT="$f" && break; done
  [ -n "$FONT" ] || { echo "[!] No TTF font found"; exit 1; }
  # Text
  TITLE_FILE="$META/${EP}_title_variants_en.txt"
  DESC_FILE="$META/${EP}_description_en.txt"
  TITLE="$(head -n1 "$TITLE_FILE" 2>/dev/null || echo 'Make Cheap Look Premium: Drag-Queen Playbook')"
  TITLE_ON="$OUT/_title_en.txt"; SUB_ON="$OUT/_subtitle_en.txt"; HOOK_TXT="$OUT/_hook_en.txt"
  [ -f "$TITLE_ON" ] || echo "$TITLE" > "$TITLE_ON"
  [ -f "$SUB_ON" ]  || echo "Big stage on a small budget — make scrappy look premium." > "$SUB_ON"
  [ -f "$HOOK_TXT" ]|| echo "You don't need money to look premium — you need focus."   > "$HOOK_TXT"
  # Narration
  cd "$OUT"
  SRC1="$DOCS/${EP}_script_en.md"; SRC2="$META/${EP}_description_en.txt"
  SRC="$([ -f "$SRC1" ] && echo "$SRC1" || { [ -f "$SRC2" ] && echo "$SRC2" || echo "$HOOK_TXT"; })"
  VOICE="$(say -v "?" 2>/dev/null | awk '/^(Samantha|Ava|Victoria)/{print $1; exit}')" || VOICE=""
  if [ ! -f narration_main.wav ]; then
    if [ -n "$VOICE" ]; then
      say -f "$SRC" -o narration.aiff -v "$VOICE" -r 180
      ffmpeg -nostdin -y -hide_banner -loglevel error -i narration.aiff -ar 48000 -ac 1 narration_main.wav
      rm -f narration.aiff
    else
      ffmpeg -nostdin -y -hide_banner -loglevel error -f lavfi -t 10 -i anullsrc=cl=mono:r=48000 narration_main.wav
    fi
  fi
  DUR="$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 narration_main.wav || echo 0)"
  if awk "BEGIN{exit !($DUR<$MAIN_TARGET)}"; then
    PAD="$(awk -v d="$DUR" -v t="$MAIN_TARGET" 'BEGIN{p=t-d; if(p<0)p=0; printf "%.3f", p}')"
    ffmpeg -nostdin -y -hide_banner -loglevel error -i narration_main.wav -filter:a "apad=pad_dur=${PAD}" -t "$MAIN_TARGET" narration_main_pad.wav
  else
    ffmpeg -nostdin -y -hide_banner -loglevel error -i narration_main.wav -t "$MAIN_TARGET" -ac 1 -ar 48000 narration_main_pad.wav
  fi
  ffmpeg -nostdin -y -hide_banner -loglevel error -i narration_main_pad.wav -t "$SHORTS_TARGET" -ac 1 -ar 48000 narration_shorts.wav

  # Captions?
  HASCAP=0; ffmpeg -hide_banner -filters 2>/dev/null | grep -q subtitles && [ -f "$CAPS/${EP}_template_en.srt" ] && HASCAP=1
  [ $HASCAP -eq 1 ] && ASSFS="Fontname=Arial,Fontsize=38,PrimaryColour=&H00FFFFFF&,OutlineColour=&H00333333&,Outline=2,Alignment=2,MarginV=90"

  # MAIN render
  MAIN="$OUT/${EP}_main_1080p.mp4"
  FCM="
[1:a]asplit=2[aout][avis];
[avis]showwaves=s=1920x360:mode=line:colors=${ACCHEX}|${SECHX},format=rgba[wave];
[0:v]format=rgba[bg];
[bg][wave]overlay=x=0:y=720[v1];
[v1]drawtext=fontfile='${FONT}':textfile='${TITLE_ON}':fontsize=72:fontcolor=#FFFFFF:x=(w-text_w)/2:y=150:enable='between(t,0,6)'[v2];
[v2]drawtext=fontfile='${FONT}':textfile='${SUB_ON}':fontsize=40:fontcolor=$(tohash "$ACCHEX"):x=(w-text_w)/2:y=240:enable='between(t,0,6)'[v3];
[v3]drawtext=fontfile='${FONT}':textfile='${HOOK_TXT}':fontsize=64:fontcolor=#FFFFFF:x=(w-text_w)/2:y='300-20*t':enable='between(t,0,3)'[v4];
[2:v]scale=w='ceil(1920*(t/${MAIN_TARGET}))':h=10:eval=frame[bar];
[v4][bar]overlay=x=0:y=1070[vpre]"
  if [ $HASCAP -eq 1 ]; then
    FCM="${FCM};[vpre]subtitles='${CAPS}/${EP}_template_en.srt':force_style='${ASSFS}'[vout]"
  else
    FCM="${FCM};[vpre]format=yuv420p[vout]"
  fi
  ffmpeg -nostdin -y -hide_banner -loglevel error \
    -f lavfi -t "$MAIN_TARGET" -r 30 -i "color=c=${BGHEX}:s=1920x1080" \
    -i narration_main_pad.wav \
    -f lavfi -t "$MAIN_TARGET" -r 30 -i "color=c=${ACCHEX}:s=1920x10" \
    -filter_complex "$FCM" -map "[vout]" -map "[aout]" \
    -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k -shortest "$MAIN"

  # SHORTS
  SHORTS="$OUT/${EP}_shorts_1080x1920.mp4"
  FCS="
[1:a]asplit=2[aout][avis];
[avis]showwaves=s=1080x440:mode=line:colors=${ACCHEX}|${SECHX},format=rgba[wave];
[0:v]format=rgba[bg];
[bg][wave]overlay=x=0:y=1480[v1];
[v1]drawtext=fontfile='${FONT}':textfile='${TITLE_ON}':fontsize=72:fontcolor=#FFFFFF:x=(w-text_w)/2:y=200:enable='between(t,0,6)'[v2];
[v2]drawtext=fontfile='${FONT}':textfile='${SUB_ON}':fontsize=38:fontcolor=$(tohash "$ACCHEX"):x=(w-text_w)/2:y=290:enable='between(t,0,6)'[v3];
[v3]drawtext=fontfile='${FONT}':textfile='${HOOK_TXT}':fontsize=60:fontcolor=#FFFFFF:x=(w-text_w)/2:y='360-25*t':enable='between(t,0,3)'[v4];
[2:v]scale=w='ceil(1080*(t/${SHORTS_TARGET}))':h=10:eval=frame[bar];
[v4][bar]overlay=x=0:y=1910[vout]"
  ffmpeg -nostdin -y -hide_banner -loglevel error \
    -f lavfi -t "$SHORTS_TARGET" -r 30 -i "color=c=${BGHEX}:s=1080x1920" \
    -i narration_shorts.wav \
    -f lavfi -t "$SHORTS_TARGET" -r 30 -i "color=c=${ACCHEX}:s=1080x10" \
    -filter_complex "$FCS" -map "[vout]" -map "[aout]" \
    -c:v libx264 -preset veryfast -crf 21 -pix_fmt yuv420p -c:a aac -b:a 160k -shortest "$SHORTS"

  # Thumbs
  TL="$META/${EP}_thumbnail_lines_en.txt"
  l1="$(sed -n '1p' "$TL" 2>/dev/null || echo 'Cheap → Premium')"
  l2="$(sed -n '2p' "$TL" 2>/dev/null || echo 'Cut • Punch • Rhythm')"
  l3="$(sed -n '3p' "$TL" 2>/dev/null || echo 'The Glue-Gun Rule')"
  mk(){ local text="$1" out="$2" box="$(tohash "$ACCHEX")33"
    ffmpeg -nostdin -y -hide_banner -loglevel error -f lavfi -i "color=c=${BGHEX}:s=1280x720" \
      -frames:v 1 -vf "drawtext=fontfile='${FONT}':text='${text}':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=96:fontcolor=#FFFFFF,drawbox=x=(w-1120)/2:y=(h-200)/2:w=1120:h=200:color=${box}:t=fill" "$out"; }
  mk "$l1" "$BASE/publish/$EP/yt_thumb_${EP}_v1.png"
  mk "$l2" "$BASE/publish/$EP/yt_thumb_${EP}_v2.png"
  mk "$l3" "$BASE/publish/$EP/yt_thumb_${EP}_v3.png"

  MDUR="$(ffprobe -v error -show_entries format=duration -of default:nk=1:nw=1 "$MAIN"   | awk '{printf "%.1fs",$1}' 2>/dev/null || echo n/a)"
  SDUR="$(ffprobe -v error -show_entries format=duration -of default:nk=1:nw=1 "$SHORTS" | awk '{printf "%.1fs",$1}' 2>/dev/null || echo n/a)"
  echo "================ BUILD RESULTS ================"
  echo "MAIN:   $MAIN ($MDUR)"
  echo "SHORTS: $SHORTS ($SDUR)"
  echo "THUMBS:"
  echo " - $BASE/publish/$EP/yt_thumb_${EP}_v1.png"
  echo " - $BASE/publish/$EP/yt_thumb_${EP}_v2.png"
  echo " - $BASE/publish/$EP/yt_thumb_${EP}_v3.png"
  echo "OUT_DIR: $BASE/publish/$EP"
  echo "==============================================="
  open -R "$BASE/publish/$EP" >/dev/null 2>&1 || true
}

publish(){
  EP="${1:-$EP_DEFAULT}"
  OUT="$BASE/publish/$EP"; mkdir -p "$OUT"
  TITLE_FILE="$META/${EP}_title_variants_en.txt"
  DESC_FILE="$META/${EP}_description_en.txt"
  TAGS_FILE="$META/${EP}_tags_en.txt"
  CHAP_FILE="$META/${EP}_chapters_en.txt"
  PIN_FILE="$META/${EP}_pinned_comment_en.txt"
  TITLE="$(head -n1 "$TITLE_FILE" 2>/dev/null || echo 'Make Cheap Look Premium: Drag-Queen Playbook')"
  DESC="$(cat "$DESC_FILE" 2>/dev/null || echo '')"
  TAGS="$(tr '\n' ',' < "$TAGS_FILE" 2>/dev/null | sed -E 's/,+/,/g; s/^,|,$//g; s/,/, /g')"
  CHAPS="$(cat "$CHAP_FILE" 2>/dev/null || echo '')"
  PINNED="$(cat "$PIN_FILE" 2>/dev/null || echo 'Your CHEAP → PREMIUM trick in one line.')"
  KIT="$OUT/UPLOAD_KIT_${EP}.md"
  cat > "$KIT" <<MD
# Upload Kit — ${EP}

## MAIN
**Title:** $TITLE

**Description:**
$DESC

**Tags (comma-separated):**
$TAGS

**Chapters:**
$CHAPS

**Pinned Comment:**
$PINNED

## SHORTS
**Title:** $(sed -n '1p' "$META/${EP}_SHORTS_title_en.txt" 2>/dev/null || echo 'Big Stage, Small Budget — 3 Rules in 30s')
**Description:**
$(cat "$META/${EP}_SHORTS_description_en.txt" 2>/dev/null || echo 'Watch the full episode on the channel.')

Paths:
- MAIN:   $OUT/${EP}_main_1080p.mp4
- SHORTS: $OUT/${EP}_shorts_1080x1920.mp4
- Thumb1: $OUT/yt_thumb_${EP}_v1.png
- Thumb2: $OUT/yt_thumb_${EP}_v2.png
- Thumb3: $OUT/yt_thumb_${EP}_v3.png
MD
  # Studio link
  CID="$(awk -F= '/^CHANNEL_ID=/{print $2}' "$LOCK" 2>/dev/null)"
  [ -n "$CID" ] || CID="UClmidwCUmSPHBUqk-hnj5Ag"
  STUDIO_URL="https://studio.youtube.com/channel/${CID}/videos/upload"
  command -v pbcopy >/dev/null 2>&1 && printf "%s" "$TITLE" | pbcopy && echo "[*] Title copied to clipboard."
  open -R "$OUT" >/dev/null 2>&1 || true
  if [ -x "/Applications/Firefox.app/Contents/MacOS/firefox" ]; then
    open -a "Firefox" --args -P "Phiando-HellinAss" -no-remote "$STUDIO_URL" >/dev/null 2>&1 || open "$STUDIO_URL" >/dev/null 2>&1 || true
  else
    open "$STUDIO_URL" >/dev/null 2>&1 || true
  fi
  echo "================ PUBLISH KIT ================"
  echo "KIT:    $KIT"
  echo "STUDIO: $STUDIO_URL"
  echo "============================================="
}

studio(){
  CID="$(awk -F= '/^CHANNEL_ID=/{print $2}' "$LOCK" 2>/dev/null)"
  [ -n "$CID" ] || CID="UClmidwCUmSPHBUqk-hnj5Ag"
  STUDIO_URL="https://studio.youtube.com/channel/${CID}/videos/upload"
  if [ -x "/Applications/Firefox.app/Contents/MacOS/firefox" ]; then
    open -a "Firefox" --args -P "Phiando-HellinAss" -no-remote "$STUDIO_URL" >/dev/null 2>&1 || open "$STUDIO_URL" >/devnull 2>&1 || true
  else
    open "$STUDIO_URL" >/dev/null 2>&1 || true
  fi
  echo "Studio: $STUDIO_URL"
}

case "$1" in
  safety) shift; sub="${1:-doctor}"; case "$sub" in doctor) safety_doctor ;; smoke) safety_smoke ;; *) echo "usage: phiando safety {doctor|smoke}"; exit 2;; esac ;;
  build)  shift; build "$@" ;;
  publish)shift; publish "$@" ;;
  studio) shift; studio ;;
  *) echo "usage: phiando {safety|build|publish|studio}"; exit 2 ;;
esac
