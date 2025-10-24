#!/usr/bin/env bash
# PHIANDO One-Click Safe Installer (English code, Turkish prompts)
# Place as: phiando_one_click.sh
set -euo pipefail

# --------- Configuration ----------
BASE_DIR="$HOME/ANGELADOLORES/PHIANDO"
VENV_DIR="$BASE_DIR/venv"
LOG_DIR="$BASE_DIR/logs"
DRAFTS_DIR="$BASE_DIR/drafts"
PUBLISHED_DIR="$BASE_DIR/published"
UI_DIR="$BASE_DIR/ui"
CORE_DIR="$BASE_DIR/core"
AGENTS_DIR="$BASE_DIR/agents"
SCRIPTS_DIR="$BASE_DIR/scripts"
KEY_DIR="$HOME/.phiando_keys"
KEY_PATH="$KEY_DIR/id_ed25519_phiando"
PLIST_PATH="$HOME/Library/LaunchAgents/com.phiando.updater.plist"
STARTER_DESKTOP="$HOME/Desktop/PhiANDO_start.command"
FLASK_PORT=3000

# --------- Helper functions ----------
info() { printf "\n[PHIANDO] %s\n" "$1"; }
err() { printf "\n[PHIANDO][ERROR] %s\n" "$1" >&2; }
confirm() {
  # $1 = prompt (Turkish)
  read -r -p "$1 [y/N]: " ans
  case "$ans" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# --------- Start ----------
info "PHIANDO One-Click: Kurulum başlıyor."

# 1) Create structure
info "Klasör yapısı oluşturuluyor: $BASE_DIR"
mkdir -p "$BASE_DIR" "$LOG_DIR" "$DRAFTS_DIR" "$PUBLISHED_DIR" "$UI_DIR" "$CORE_DIR" "$AGENTS_DIR" "$SCRIPTS_DIR"

# 2) Create minimal python project files (persona + server + ui)
info "Persona ve UI dosyaları yaratılıyor."

cat > "$CORE_DIR/persona.py" <<'PY'
# persona.py  -- minimal safe persona engine
import os, json
from datetime import datetime

BASE = os.path.dirname(__file__)
ROOT = os.path.normpath(os.path.join(BASE, ".."))
DRAFTS = os.path.join(ROOT, "drafts")
os.makedirs(DRAFTS, exist_ok=True)

class PhiPersona:
    def __init__(self, name="PhiANDO_NOVA"):
        self.name = name
        self.theme = "Golden Performer"

    def create_draft(self, title, body, tags=None):
        if tags is None: tags = []
        draft = {"title": title, "body": body, "tags": tags, "created": datetime.utcnow().isoformat()}
        fname = os.path.join(DRAFTS, f"draft_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json")
        with open(fname, "w", encoding="utf-8") as f:
            json.dump(draft, f, ensure_ascii=False, indent=2)
        return fname

    def suggest_social_post(self, seed="evening performance"):
        title = f"{self.theme} — {seed}"
        body = (
            f"{self.name} shares a moment:\\n\\n"
            f"Tonight the stage meets neon and classical tragedy. Movement aligned with golden ratio.\\n\\n"
            f"#phiando #performance"
        )
        return self.create_draft(title, body, tags=["performance","art"])
PY

cat > "$CORE_DIR/README.txt" <<'TXT'
PHIANDO core files.
Persona engine (persona.py).
TXT

# 3) Flask server (reviewer UI)
cat > "$CORE_DIR/server.py" <<'PY'
# server.py  -- simple reviewer UI
from flask import Flask, jsonify, request, send_from_directory
import os, json

ROOT = os.path.dirname(__file__)
PROJECT_ROOT = os.path.normpath(os.path.join(ROOT, ".."))
DRAFTS = os.path.join(PROJECT_ROOT, "drafts")
PUBLISHED = os.path.join(PROJECT_ROOT, "published")
os.makedirs(DRAFTS, exist_ok=True)
os.makedirs(PUBLISHED, exist_ok=True)

app = Flask(__name__, static_folder=os.path.join(PROJECT_ROOT, "ui"), static_url_path="/")

@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")

@app.route("/api/drafts")
def list_drafts():
    files = sorted([f for f in os.listdir(DRAFTS) if f.endswith(".json")], reverse=True)
    drafts = []
    for fn in files:
        with open(os.path.join(DRAFTS, fn), "r", encoding="utf-8") as fh:
            drafts.append({"filename": fn, "content": json.load(fh)})
    return jsonify(drafts)

@app.route("/api/publish", methods=["POST"])
def publish():
    payload = request.get_json()
    fname = payload.get("filename")
    if not fname:
        return {"error":"filename required"}, 400
    src = os.path.join(DRAFTS, fname)
    dst = os.path.join(PUBLISHED, fname)
    if not os.path.exists(src):
        return {"error":"not found"}, 404
    os.rename(src, dst)
    return {"status":"moved", "to": dst}

if __name__ == "__main__":
    app.run(port=int(os.environ.get("PHIANDO_PORT", "3000")), debug=False)
PY

# 4) simple UI
cat > "$UI_DIR/index.html" <<'HTML'
<!doctype html>
<html>
<head><meta charset="utf-8"><title>PhiANDO Reviewer</title></head>
<body style="font-family:Helvetica,Arial,sans-serif;margin:20px;">
  <h1>PhiANDO Draft Reviewer (TR/EN)</h1>
  <div id="list">loading…</div>
  <p>Not: "Approve" sadece yerel 'published' klasörüne taşır. Yayınlama gerçek hesaplarla manuel onay gerektirir.</p>
  <script>
    async function load() {
      const res = await fetch("/api/drafts");
      const drafts = await res.json();
      const el = document.getElementById("list");
      el.innerHTML = "";
      drafts.forEach(d => {
        const card = document.createElement("div");
        card.style.border="1px solid #ccc"; card.style.margin="8px"; card.style.padding="12px";
        card.innerHTML = `<h3>${d.content.title}</h3><pre style="white-space:pre-wrap">${d.content.body}</pre>
          <button onclick='publish("${d.filename}")'>Approve & Move (simulate publish)</button>`;
        el.appendChild(card);
      });
    }
    async function publish(fn){
      await fetch("/api/publish", {method:"POST",headers:{"content-type":"application/json"}, body: JSON.stringify({filename:fn})});
      load();
    }
    load();
  </script>
</body>
</html>
HTML

# 5) requirements
cat > "$BASE_DIR/requirements.txt" <<'REQ'
Flask>=2.0
REQ

# 6) create a small helper starter script in project
cat > "$SCRIPTS_DIR/phiando_start.sh" <<'SH'
#!/usr/bin/env bash
# start phiando (assumes venv is activated by this script)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
source "$ROOT/venv/bin/activate"
export PHIANDO_PORT=3000
nohup python3 "$ROOT/core/server.py" > "$ROOT/logs/server.log" 2>&1 &
sleep 1
echo "PhiANDO server started on http://localhost:3000 (logs: $ROOT/logs/server.log)"
SH
chmod +x "$SCRIPTS_DIR/phiando_start.sh"

# 7) virtualenv and install (ask network permission)
if confirm "Paket yüklemesi yapmam (internet gerekir) ve venv oluşturayım? (pip install)"; then
  # create venv
  if ! command -v python3 >/dev/null 2>&1; then
    err "python3 bulunamadı. Lütfen Xcode command line tools ve Python yükleyin."
    exit 1
  fi
  python3 -m venv "$VENV_DIR"
  # pip install
  info "Sanal ortam hazırlanıyor ve gerekli paketler yükleniyor (Flask). Bu ağ bağlantısı kullanır."
  # Use pip via venv
  "$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null
  "$VENV_DIR/bin/pip" install -r "$BASE_DIR/requirements.txt"
else
  info "Paket yüklemesi atlandı. Çalıştırma için elle 'venv' kurmalı ve Flask yüklemelisiniz."
fi

# 8) generate an SSH key for safe repo access (if not exists)
if [ ! -f "$KEY_PATH" ]; then
  info "SSH key oluşturuluyor (yerel, şifre yok). Public key'i GitHub'a ekleyin (Settings -> SSH and GPG keys)."
  mkdir -p "$KEY_DIR" && chmod 700 "$KEY_DIR"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "phiando@$(hostname)-local" -N "" >/dev/null
  chmod 600 "$KEY_PATH"
  info "Public key:"
  cat "${KEY_PATH}.pub"
  echo
  if command -v pbcopy >/dev/null 2>&1; then
    cat "${KEY_PATH}.pub" | pbcopy && info "Public key clipboard'a kopyalandı."
  fi
else
  info "SSH key zaten mevcut: $KEY_PATH"
fi

# 9) create disabled LaunchAgent (safe updater scaffold)
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>com.phiando.updater</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/true</string>
    </array>
    <key>StartInterval</key><integer>86400</integer>
    <key>RunAtLoad</key><false/>
  </dict>
</plist>
PLIST
chmod 644 "$PLIST_PATH"

# 10) create Desktop starter (double-click)
cat > "$STARTER_DESKTOP" <<'CMD'
#!/usr/bin/env bash
# Desktop starter for PhiANDO (double-click)
PROJECT="$HOME/ANGELADOLORES/PHIANDO"
VENV="$PROJECT/venv"
if [ -f "$VENV/bin/activate" ]; then
  source "$VENV/bin/activate"
else
  echo "Virtualenv yok veya aktiv edilemedi. Lütfen önce venv oluşturun."
fi
# start server
nohup python3 "$PROJECT/core/server.py" > "$PROJECT/logs/server.log" 2>&1 &
sleep 1
open "http://localhost:3000"
# Try to open VS Code if installed and compatible
if [ -d "/Applications/Visual Studio Code.app" ]; then
  # check macOS version
  OSVER=$(sw_vers -productVersion)
  MAJOR=$(echo "$OSVER" | cut -d. -f1)
  if [ "$MAJOR" -ge 11 ]; then
    open -a "Visual Studio Code" "$PROJECT"
  else
    echo "VS Code sürümü macOS '$OSVER' ile uyumlu olmayabilir. Manuel kontrol edin."
  fi
fi
CMD
chmod +x "$STARTER_DESKTOP"

# 11) create small example draft using persona
info "İlk örnek taslak üretiliyor."
# run persona script to create a draft (use system python)
python3 - <<PY
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), "core"))
from core import persona as p_mod
p = p_mod.PhiPersona()
path = p.suggest_social_post("initial soliloquy")
print("Draft created:", path)
PY

# 12) start server now (if venv exists)
if [ -f "$VENV_DIR/bin/activate" ]; then
  info "Sunucu çalıştırılıyor (arka planda). Log: $LOG_DIR/server.log"
  source "$VENV_DIR/bin/activate"
  nohup python3 "$CORE_DIR/server.py" > "$LOG_DIR/server.log" 2>&1 &
  sleep 1
  # open browser
  if command -v open >/dev/null 2>&1; then
    open "http://localhost:$FLASK_PORT"
  fi
else
  info "Sanal ortam kurulmamış. Server elle başlatmak için: source $VENV_DIR/bin/activate && python3 $CORE_DIR/server.py"
fi

# 13) final messages (Turkish)
echo
info "Kurulum tamamlandı."
echo "Proje klasörü: $BASE_DIR"
echo "Drafts: $DRAFTS_DIR"
echo "Published (lokal): $PUBLISHED_DIR"
echo "Starter (double-click): $STARTER_DESKTOP"
echo "SSH public key (add to GitHub if you want updater/repo access):"
echo "  ${KEY_PATH}.pub"
echo
info "Güvenlik notu: Bu kurulum hiçbir sosyal medya hesabına otomatik paylaşım yapmaz."
info "Yayın veya ağ eylemleri gerektiğinde PhiANDO sizden açık onay isteyecek."
info "Devam etmek istiyorsanız: Masaüstündeki PhiANDO_start.command çift tıklayın veya terminalden:"
echo "  bash $SCRIPTS_DIR/phiando_start.sh"
echo
info "PhiANDO şu anda http://localhost:$FLASK_PORT adresinde çalışıyor (eğer venv kurulup server başlatıldıysa)."
info "İsterseniz ben bu betiği ZIP haline getirmenizi veya VSCode uyumluluğunu otomatik düzeltmeyi gösteririm."

exit 0

