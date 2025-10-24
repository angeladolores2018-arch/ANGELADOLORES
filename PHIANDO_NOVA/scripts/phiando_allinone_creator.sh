#!/bin/bash
echo "🌀 PhiANDO_NOVA Genesis — All-in-One Creator"
sleep 1

# 1️⃣ Yol & Hedef
BASE="$HOME/ANGELADOLORES/PHIANDO_NOVA"
mkdir -p "$BASE"
cd "$BASE" || exit 1

# 2️⃣ Ana dizinler
for d in core performance ui economy data scripts; do
  mkdir -p "$BASE/$d"
done

# 3️⃣ Varsayılan dosyalar
echo '{"name": "PhiANDO", "archetype": "drag-geisha-android", "languages": ["tr", "en", "jp"], "creed": "beauty is logic in motion"}' > "$BASE/core/phi_persona.json"
echo "import sqlite3, os\nprint('🧠 Phi Core initialized')" > "$BASE/core/phi_core.py"
sqlite3 "$BASE/core/phi_brain.sqlite" "CREATE TABLE memory (id INTEGER PRIMARY KEY, input TEXT, output TEXT, emotion TEXT);"
sqlite3 "$BASE/economy/ledger.db" "CREATE TABLE earnings (id INTEGER PRIMARY KEY, source TEXT, amount REAL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"

# 4️⃣ Basit web arayüzü
cat > "$BASE/ui/index.html" <<'HTML'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>PhiANDO_NOVA</title></head>
<body style="font-family:monospace;background:black;color:#00ffaa;text-align:center;margin-top:10%">
<h1>🌸 PhiANDO_NOVA Stage</h1>
<p>Digital Madonna is awakening...</p>
</body>
</html>
HTML

# 5️⃣ Yerel sunucu
cat > "$BASE/ui/runtime_link.js" <<'JS'
import http from "http";
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end("<h1>🌸 PhiANDO_NOVA Active</h1>");
}).listen(3000, ()=>console.log("💫 UI ready at http://localhost:3000"));
JS

# 6️⃣ Başlatıcı
cat > "$BASE/scripts/phiando" <<'SH'
#!/bin/bash
echo "🚀 Launching PhiANDO_NOVA..."
cd "$(dirname "$0")/.." || exit 1
python3 core/phi_core.py &
open http://localhost:3000
echo "🌸 PhiANDO is alive at http://localhost:3000"
SH
chmod +x "$BASE/scripts/phiando"

# 7️⃣ Tamamlandı
echo "✅ PhiANDO_NOVA All-in-One kurulumu tamamlandı!"
echo "Çalıştırmak için: $BASE/scripts/phiando"

