#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os
BASE = os.path.dirname(os.path.abspath(__file__))
IMAGES_DIR = os.path.join(BASE, "..", "images")
os.makedirs(IMAGES_DIR, exist_ok=True)

# Base canvas 150x150 PNG for watermark
canvas = Image.new('RGBA', (150, 150), (0, 0, 0, 0))
draw = ImageDraw.Draw(canvas)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 12)
except:
    font = ImageFont.load_default()

# 1. Neon Lips Watermark
draw.text((10, 10), "Hell in Ass", fill=(255, 215, 0, 255), font=font)
draw.text((10, 100), "Subscribe", fill=(128, 0, 128, 255), font=font)
canvas.save(os.path.join(IMAGES_DIR, "watermark.png"))

# 2. Angela & Dolores Duo Thumbnail (1080x1920)
duo_canvas = Image.new('RGB', (1080, 1920), (50, 0, 50))  # Purple background
draw_duo = ImageDraw.Draw(duo_canvas)
draw_duo.text((100, 100), "Angela & Dolores", fill=(255, 215, 0, 255), font=font)
draw_duo.text((100, 200), "Hell in Ass Show", fill=(255, 0, 255, 255), font=font)
draw_duo.text((100, 1800), "Subscribe for Chaos!", fill=(255, 215, 0, 255), font=font)
duo_canvas.save(os.path.join(IMAGES_DIR, "duo_thumbnail.png"))

# 3. Runway Varyasyon
runway_canvas = Image.new('RGB', (1080, 1920), (0, 0, 50))  # Dark neon
draw_runway = ImageDraw.Draw(runway_canvas)
draw_runway.text((100, 100), "Runway Read", fill=(255, 215, 0, 255), font=font)
draw_runway.text((100, 200), "Slay or Flop?", fill=(255, 0, 255, 255), font=font)
runway_canvas.save(os.path.join(IMAGES_DIR, "runway_varyasyon.png"))

print("✅ Görseller üretildi: images/watermark.png, duo_thumbnail.png, runway_varyasyon.png")
