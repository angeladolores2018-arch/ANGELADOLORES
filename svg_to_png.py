#!/usr/bin/env python3
import sys
import subprocess
import os

# SVG ve PNG dosya yolları
SVG_FILE = os.path.expanduser("~/ANGELADOLORES/publish/cover.svg")
PNG_FILE = os.path.expanduser("~/ANGELADOLORES/publish/cover.png")

# Cairo / cairosvg kontrolü ve yükleme
try:
    import cairosvg
except ImportError:
    print("cairosvg bulunamadı, yükleniyor...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cairosvg"])

# Cairo kütüphanesi var mı kontrol et
def check_cairo_lib():
    import ctypes.util
    for lib_name in ["cairo-2", "cairo", "libcairo-2"]:
        if ctypes.util.find_library(lib_name):
            return True
    return False

if not check_cairo_lib():
    print("⚠️ Sistem Cairo kütüphanesi bulunamadı, Homebrew kullanarak yüklemeniz gerekir:")
    print("   brew install --build-from-source cairo")
    print("   (veya Cairo'yı elle kurun)")
    sys.exit(1)

# SVG → PNG dönüştür
if os.path.isfile(SVG_FILE):
    print(f"🔹 {SVG_FILE} → {PNG_FILE} dönüştürülüyor...")
    cairosvg.svg2png(url=SVG_FILE, write_to=PNG_FILE)
    print("✅ Dönüştürme tamamlandı!")
else:
    print(f"⚠️ SVG dosyası bulunamadı: {SVG_FILE}")
    sys.exit(1)

