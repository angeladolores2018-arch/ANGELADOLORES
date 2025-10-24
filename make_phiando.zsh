#!/bin/zsh
set -Eeuo pipefail

BASE="$HOME/ANGELADOLORES"
export PATH="$BASE/bin:$PATH"

FFMPEG="$(command -v ffmpeg)"  || { echo "[ERR] ffmpeg yok";  exit 1; }
FFPROBE="$(command -v ffprobe)"|| { echo "[ERR] ffprobe yok"; exit 1; }

# Python3 varsa onu kullan; yoksa başlığı ASCII fallback ile ver
USE_PY3=0
if command -v python3 >/dev/null 2>&1; then
  USE_PY3=1
fi

# --- Publish klasörü ---
PUB_ID=""
[ -f "$BASE/publish/last.txt" ] && PUB_ID="$(cat "$BASE/publish/last.txt")"
[ -n "$PUB_ID" ] || { echo "[ERR] publish yok ( $BASE/publish/last.txt bulunamadı )"; exit 1; }
FOLDER="$BASE/publish/$PUB_ID"
cd "$FOLDER" || { echo "[ERR] klasör yok: $FOLDER"; exit 1; }

echo "[*] Working in: $FOLDER"

# --- Başlık dosyası (_title.txt) ---
if [ "$USE_PY3" -eq 1 ] && [ -f post.json ]; then
  python3 - <<'PY' > _title.txt
# -*- coding: utf-8 -*-
import json
try:
    print(json.load(open("post.json", "r", encoding="utf-8"))["seed"]["title"])
except Exception:
    print("Phiando - Episode 1")
PY
else
  echo "Phiando - Episode 1" > _title.txt
fi

# --- Görsel kaynak (varsa kullan) ---
IMG=""
for c in cover_1920x1080.png cover.png cover.svg.png; do
  [ -f "$c" ] && IMG="$c" && break
done

# --- Güvenli scale/pad filtreleri (drawtext yok; TR karakter sorunlarını by-pass) ---
F169='scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black'
F916='scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black'

# --- Arka plan klipleri ---
if [ -n "$IMG" ]; then
  "$FFMPEG" -y -hide_banner -loglevel error -loop 1 -i "$IMG" -vf "$F169" -t 2 -r 30 -c:v libx264 -pix_fmt yuv420p _bg_1920x1080.mp4
  "$FFMPEG" -y -hide_banner -loglevel error -loop 1 -i "$IMG" -vf "$F916" -t 2 -r 30 -c:v libx264 -pix_fmt yuv420p _bg_1080x1920.mp4
else
  "$FFMPEG" -y -hide_banner -loglevel error -f lavfi -i color=c=black:s=1920x1080:d=2 -r 30 -c:v libx264 -pix_fmt yuv420p _bg_1920x1080.mp4
  "$FFMPEG" -y -hide_banner -loglevel error -f lavfi -i color=c=black:s=1080x1920:d=2 -r 30 -c:v libx264 -pix_fmt yuv420p _bg_1080x1920.mp4
fi

# --- Narration metni: voiceover.txt > script.md > _title.txt ---
TXT="voiceover.txt"
[ -f "$TXT" ] || TXT="script.md"
[ -f "$TXT" ] || TXT="_title.txt"

# --- TTS -> WAV (macOS 'say') ---
VOICE="$(say -v "?" | awk '/^(Yelda|Zeynep|Samantha) /{print $1; exit}')"; [ -n "$VOICE" ] || VOICE="Samantha"
say -f "$TXT" -o narration.aiff -v "$VOICE" -r 170
"$FFMPEG" -y -hide_banner -loglevel error -i narration.aiff -ar 48000 -ac 1 narration.wav

# --- Süre ---
DUR="$("$FFPROBE" -v error -show_entries format=duration -of default=nk=1:nw=1 narration.wav || echo 10)"
DUR_INT="$(printf "%.0f\n" "${DUR:-10}")"; [ "$DUR_INT" -lt 8 ] && DUR_INT=8

# --- Render ---
MAIN="S1E01_main_1080p.mp4"
SHORTS="S1E01_shorts_1080x1920.mp4"

"$FFMPEG" -y -hide_banner -loglevel error -stream_loop -1 -i _bg_1920x1080.mp4 -i narration.wav \
  -t "$DUR_INT" -r 30 -c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 22 -c:a aac -b:a 160k -shortest "$MAIN"

"$FFMPEG" -y -hide_banner -loglevel error -stream_loop -1 -i _bg_1080x1920.mp4 -i narration.wav \
  -t "$DUR_INT" -r 30 -c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 23 -c:a aac -b:a 160k -shortest "$SHORTS"

# --- YouTube thumb ---
"$FFMPEG" -y -hide_banner -loglevel error -i "$MAIN" -frames:v 1 yt_thumb_1280x720.png

# --- Özet ---
echo "================ OUTPUTS ================"
echo "PUB_ID: $PUB_ID"
echo "MAIN:   $PWD/$MAIN"
echo "SHORTS: $PWD/$SHORTS"
"$FFPROBE" -v error -show_entries format=duration -of default=nk=1:nw=1 "$MAIN"   | awk '{printf "MAIN_DUR:   %.1fs\n",$1}'
"$FFPROBE" -v error -show_entries format=duration -of default=nk=1:nw=1 "$SHORTS" | awk '{printf "SHORTS_DUR: %.1fs\n",$1}'
echo "THUMB:  $PWD/yt_thumb_1280x720.png"
echo "VOICE:  $VOICE"
echo "========================================"

# Finder'da göster + QuickTime'da aç (sessizce)
open -R "$MAIN"   >/dev/null 2>&1 || true
open -R "$SHORTS" >/dev/null 2>&1 || true
open -a "QuickTime Player" "$MAIN" >/dev/null 2>&1 || true
