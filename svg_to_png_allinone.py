#!/usr/bin/env python3
import os,sys,glob,subprocess
from pathlib import Path
base=Path(os.path.dirname(os.path.realpath(__file__))).resolve();svg_dir=base/"publish";png_dir=base/"png";svg_dir.mkdir(parents=True,exist_ok=True);png_dir.mkdir(parents=True,exist_ok=True);svgs=list(svg_dir.glob("*.svg"));
if not svgs: print(f"⚠ Hiç SVG dosyası bulunamadı: {svg_dir}"); sys.exit(1)
for svg in svgs:
    out=png_dir/(svg.stem+".png");
    try:
        import cairosvg
        cairosvg.svg2png(url=str(svg),write_to=str(out))
        print(f"✔ Converted: {svg.name} -> {out}")
    except Exception as e1:
        try:
            subprocess.run(["rsvg-convert","-o",str(out),str(svg)],check=True)
            print(f"✔ Converted with rsvg-convert: {svg.name} -> {out}")
        except Exception:
            try:
                subprocess.run(["inkscape",str(svg),"--export-filename="+str(out)],check=True)
                print(f"✔ Converted with inkscape: {svg.name} -> {out}")
            except Exception as e:
                print(f"✖ Failed to convert {svg.name}: {e}")

