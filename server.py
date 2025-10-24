from flask import Flask, jsonify, request, Response, send_file
import time, os, json, base64, pathlib, zipfile, io, re

app = Flask(__name__)
app.config['DEBUG'] = False

BASE = os.getcwd()
RUNTIME = os.path.join(BASE, "runtime")
PROD = os.path.join(BASE, "production")
PUB = os.path.join(BASE, "publish")
pathlib.Path(RUNTIME).mkdir(parents=True, exist_ok=True)
pathlib.Path(PROD).mkdir(parents=True, exist_ok=True)
pathlib.Path(PUB).mkdir(parents=True, exist_ok=True)

# ---------- Core ----------
@app.get("/intelligence/feed")
def get_critical_feed():
    return jsonify({"status":"OK","core":"Angela (Observation)","api_name":"intelligence_feed (V31)","timestamp":int(time.time()),
                    "critical_topics":[{"topic_id":"T001","title":"Futuristic Fashion Critique","priority":"HIGH"},
                                       {"topic_id":"T002","title":"Neon Art Scandal Analysis","priority":"MEDIUM"}],
                    "message":"Angela Core: Critical Feed successfully retrieved and ready for the next cycle."})

@app.post("/mac/notify")
def send_notification():
    _ = request.get_json(silent=True) or {}
    return jsonify({"status":"Notification Sent","core":"Dolores (Reaction)","message":"Viral Moment Detected! Mac Notification Sent.","api_name":"mac_notify (V24)"} )

@app.get("/system/optimize")
def system_optimize():
    tasks = ["Cleared Browser Cache","Stopped 5 Background Apps","Maximized RAM Allocation"]
    return jsonify({"status":"READY","message":"Operative Readiness (O) Achieved. Mac is optimized for critical output.","tasks_executed":tasks,"latency_ms":15})

@app.get("/system/snapshot")
def system_snapshot():
    pathlib.Path(os.path.join(BASE, "images_output")).mkdir(parents=True, exist_ok=True)
    fake_b64 = "BASE64_IMAGE_DATA_SIMULATED_BY_IMAGEN_3.0"
    with open(os.path.join(BASE, "images_output", "knall_thumbnail_base64.txt"), "w") as f:
        f.write(fake_b64)
    snap = {"snapshot_id": f"KNALL-{int(time.time())}","captured_emotion":"Shock/Rage","resolution":"1024x1024",
            "prompt_used":"A high-contrast, dramatic thumbnail image of a futuristic fashion critic in shock and rage, minimalist neon background.",
            "base64_image": fake_b64,"model":"imagen-3.0-generate-002"}
    return jsonify({"status":"GENERATED","core":"Dolores (Creative Power)","api_name":"system_snapshot (V40 - Imagen)","data":snap,
                    "message":"Dolores Core: High-impact KNALL visual generated using Imagen 3.0."})

@app.post("/content/render_qiskit")
def render_content():
    render_id = f"RENDER-{int(time.time())}"
    target_path = os.path.join(PROD, render_id)
    pathlib.Path(target_path).mkdir(parents=True, exist_ok=True)
    files = ["knall_thumbnail_base64.txt","critique_script.txt","audio_template.wav"]
    open(os.path.join(target_path,"knall_thumbnail_base64.txt"),"w").write("BASE64_IMAGE_DATA_SIMULATED_BY_IMAGEN_3.0")
    open(os.path.join(target_path,"critique_script.txt"),"w").write("Draft critique script…")
    open(os.path.join(target_path,"audio_template.wav"),"wb").write(b"")
    return jsonify({"status":"TRANSFER_COMPLETE","message":"Environment Execution (O) Success. All production assets transferred.",
                    "render_id":render_id,"target_path":target_path,"files":files})

@app.get("/status/analysis")
def status_analysis():
    analysis_data = {"content_id":"RENDER-1761068247","viral_score":9.3,
                     "metrics":{"ctr":"16.5%","retention_rate":"68%","share_rate":"4.5%"},
                     "feedback_loop":{"conclusion":"Imagen 3.0 optimized emotional contrast.","recommendation":"Transition to Auto-Zsh for instantaneous deployment."}}
    return jsonify({"status":"ANALYSIS_COMPLETE","message":"Final Status Report (S) completed. Feedback loop initiated for next K-cycle.","data":analysis_data})

@app.get("/system/next_command")
def get_next_command():
    return jsonify({"status":"NEXT_ACTION_READY","next_step_name":"Re-initiating Critical Feed (K) - New Cycle Start",
                    "terminal_command":"curl http://localhost:3000/intelligence/feed","reasoning":"Close loop and fetch next viral topic."})

# Version bump
@app.get("/status")
def status():
    return jsonify({"system":"PhiANDO NOVA Dual Core","status":"running","base":BASE,"version":"V4.4 - Dashboard+Release"})

@app.get("/")
def home():
    return "PhiANDO NOVA Dual Core OS Aktif!"

# ---------- Seeding + Publish ----------
def _priority_key(seed):
    pr=(seed.get("priority") or "MEDIUM").upper()
    order={"HIGH":0,"MEDIUM":1,"LOW":2}
    return order.get(pr,1)

@app.post("/intelligence/seed")
def intelligence_seed():
    body = request.get_json(silent=True) or {}
    seeds = body.get("seeds") or [
        {"id":"S001","title":"Post-Internet Couture vs Fast AI","priority":"HIGH","mood":"rage","visual":"neon-minimal","angle":"critique"},
        {"id":"S002","title":"Museum NFTs After the Hype","priority":"MEDIUM","mood":"curious","visual":"duotone","angle":"reportage"},
        {"id":"S003","title":"Analog Film Revival in AI Age","priority":"HIGH","mood":"nostalgia","visual":"grainy","angle":"op-ed"},
        {"id":"S004","title":"Queer Futures in Algorithmic Fashion","priority":"MEDIUM","mood":"bold","visual":"chrome","angle":"essay"}
    ]
    chosen = sorted(seeds, key=_priority_key)[0]
    pathlib.Path(RUNTIME).mkdir(parents=True, exist_ok=True)
    with open(os.path.join(RUNTIME,"seed.json"),"w") as f:
        json.dump({"chosen":chosen,"all":seeds,"stamp":int(time.time())},f,indent=2)
    return jsonify({"status":"SEEDED","chosen":chosen,"total":len(seeds)})

@app.post("/publish")
def publish():
    body = request.get_json(silent=True) or {}
    src = body.get("source_auto")
    if not src:
        autos = sorted([p for p in pathlib.Path(PROD).glob("auto_*") if p.is_dir()], key=lambda p:p.name, reverse=True)
        src = str(autos[0]) if autos else None
    seed_path = os.path.join(RUNTIME,"seed.json")
    seed = json.load(open(seed_path))["chosen"] if os.path.exists(seed_path) else {"title":"Untitled","mood":"neutral"}
    analysis_path = os.path.join(src,"analysis.json") if src else None
    analysis = json.load(open(analysis_path))["data"] if (analysis_path and os.path.exists(analysis_path)) else {}
    def svg_data(title,mood):
        t = re.sub(r"\s+"," ",title)[:60]
        s="<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='576'><rect width='100%' height='100%' fill='black'/>" \
          f"<text x='50%' y='48%' fill='white' font-size='54' font-family='Arial' text-anchor='middle'>{t}</text>" \
          f"<text x='50%' y='60%' fill='lime' font-size='28' font-family='Arial' text-anchor='middle'>mood: {mood}</text></svg>"
        return "data:image/svg+xml;base64,"+base64.b64encode(s.encode()).decode()
    publish_id = f"PUB-{int(time.time())}"
    folder = os.path.join(PUB,publish_id); pathlib.Path(folder).mkdir(parents=True, exist_ok=True)
    post = {"publish_id":publish_id,"seed":seed,"analysis":analysis,"source_auto":src}
    open(os.path.join(folder,"post.json"),"w").write(json.dumps(post,indent=2))
    img = svg_data(seed.get("title","Untitled"), seed.get("mood","neutral"))
    html = "<!doctype html><html><head><meta charset='utf-8'><title>"+seed.get('title','Untitled')+"</title>" \
           "<style>body{margin:0;background:#111;color:#eee;font-family:system-ui}.wrap{max-width:960px;margin:32px auto;padding:16px}" \
           "h1{font-size:28px}.card{background:#1b1b1b;border-radius:16px;padding:16px;box-shadow:0 6px 24px #0009}img{width:100%;border-radius:12px}" \
           "a{color:#8ef}</style></head><body><div class='wrap'>" \
           "<h1>"+seed.get('title','Untitled')+"</h1><div class='card'><img alt='preview' src='"+img+"'></div>" \
           "<div class='card'><pre>"+json.dumps(analysis,indent=2)+"</pre></div></div></body></html>"
    open(os.path.join(folder,"index.html"),"w").write(html)
    open(os.path.join(PUB,"last.txt"),"w").write(publish_id)
    return jsonify({"status":"PUBLISHED","publish_id":publish_id,"view_url":f"/publish/view/{publish_id}","folder":folder})

@app.get("/publish/last")
def publish_last():
    p=os.path.join(PUB,"last.txt")
    if not os.path.exists(p): return jsonify({"status":"EMPTY"})
    pid=open(p).read().strip()
    return jsonify({"status":"OK","publish_id":pid,"view_url":f"/publish/view/{pid}"})

@app.get("/publish/view/<pub_id>")
def publish_view(pub_id):
    path=os.path.join(PUB,pub_id,"index.html")
    if not os.path.exists(path): return Response("Not found",status=404)
    return Response(open(path,"rb").read(),mimetype="text/html")

# ---------- Script + Cover + Shotlist + Voice + Social + Export ----------
def _pub_folder(pub_id):
    folder=os.path.join(PUB,pub_id)
    pathlib.Path(folder).mkdir(parents=True, exist_ok=True)
    return folder

@app.post("/script/generate")
def script_generate():
    body=request.get_json(silent=True) or {}
    pub_id=body.get("publish_id"); tone=body.get("tone","critical-but-playful"); length=body.get("length","medium")
    folder=_pub_folder(pub_id)
    post=json.load(open(os.path.join(folder,"post.json")))
    title=post["seed"].get("title","Untitled"); mood=post["seed"].get("mood","neutral")
    analysis=post.get("analysis",{})
    beats=["# Hook\nHot take in one line.","## Thesis\nWhat’s actually going on & why it matters.",
           "## Beat 1 — Evidence\nCite concrete trend/visual cue.","## Interlude — Context\nA brief nod to history for credibility.",
           "## Beat 2 — Contrast\nShow the opposite case for tension.","## Beat 3 — Synthesis\nBridge to a takeaway for creators.",
           "## CTA\n“Save/share if this hit a nerve.”"]
    beats_md = "\n\n".join(beats)
    ctr=analysis.get('metrics',{}).get('ctr','?'); ret=analysis.get('metrics',{}).get('retention_rate','?'); share=analysis.get('metrics',{}).get('share_rate','?')
    md = f"""---
title: "{title}"
mood: "{mood}"
tone: "{tone}"
length: "{length}"
---

{beats_md}

> Metrics hint: CTR={ctr} • Retention={ret} • Share={share}
"""
    path=os.path.join(folder,"script.md"); open(path,"w").write(md)
    return jsonify({"status":"SCRIPT_OK","publish_id":pub_id,"path":path})

@app.post("/shotlist/generate")
def shotlist_generate():
    body=request.get_json(silent=True) or {}
    pub_id=body.get("publish_id"); duration=int(body.get("duration_sec",60))
    folder=_pub_folder(pub_id); script_path=os.path.join(folder,"script.md")
    if os.path.exists(script_path):
        lines=[l.strip() for l in open(script_path).read().splitlines()]
        beats=[l for l in lines if l.startswith("#")]
        if not beats: beats=["Hook","Thesis","Beat 1","Beat 2","Beat 3","CTA"]
    else:
        beats=["Hook","Thesis","Beat 1","Beat 2","Beat 3","CTA"]
    n=len(beats); seg=max(1,int(duration/max(1,n)))
    out=[]; t=0
    for i,bt in enumerate(beats,1):
        start=t; end=min(duration,start+seg if i<n else duration); t=end
        out.append({"index":i,"start_sec":start,"end_sec":end,"beat":bt,"visual_cue":"neon-minimal / bold type"})
    path=os.path.join(folder,"shotlist.json"); open(path,"w").write(json.dumps(out,indent=2))
    return jsonify({"status":"SHOTLIST_OK","publish_id":pub_id,"path":path,"count":len(out),"duration_sec":duration})

def _sec_to_ts(s):
    m=s//60; sec=s%60
    return f"{m:02d}:{sec:02d}.000"

@app.post("/voice/plan")
def voice_plan():
    body=request.get_json(silent=True) or {}
    pub_id=body.get("publish_id"); wpm=int(body.get("wpm",150))
    folder=_pub_folder(pub_id); script_path=os.path.join(folder,"script.md")
    base_text = open(script_path).read() if os.path.exists(script_path) else "Hook. Thesis. Beat 1. Beat 2. Beat 3. CTA."
    parts=[p.strip() for p in re.split(r"\n#+\s", base_text) if p.strip()]
    timings=[]; t=0
    for i,p in enumerate(parts,1):
        words=len(re.findall(r"\w+", p)); seconds=max(3,int(words*60/wpm))
        start_ts=_sec_to_ts(t); end_ts=_sec_to_ts(t+seconds); t+=seconds
        timings.append((i,p,start_ts,end_ts))
    vtt_path=os.path.join(folder,"voiceover.vtt"); txt_path=os.path.join(folder,"voiceover.txt")
    with open(vtt_path,"w") as f:
        f.write("WEBVTT\n\n")
        for i,p,st,et in timings:
            f.write(f"{i}\n{st} --> {et}\n{p}\n\n")
    with open(txt_path,"w") as f:
        for _,p,_,_ in timings:
            f.write(p+"\n\n")
    return jsonify({"status":"VOICEPLAN_OK","publish_id":pub_id,"vtt":vtt_path,"txt":txt_path,"segments":len(timings)})

def _svg_cover(w,h,title,subtitle):
    safe_title=re.sub(r"[\n\r\t]+"," ",title)[:60]
    s = f"<svg xmlns='http://www.w3.org/2000/svg' width='{w}' height='{h}'>" \
        f"<defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0%' stop-color='#0ff'/>" \
        f"<stop offset='100%' stop-color='#80f'/></linearGradient></defs>" \
        f"<rect width='100%' height='100%' fill='url(#g)'/>" \
        f"<rect x='32' y='32' width='{int(w)-64}' height='{int(h)-64}' rx='32' fill='black' fill-opacity='0.55'/>" \
        f"<text x='50%' y='46%' fill='white' font-size='{int(min(w,h)*0.05)}' font-family='Arial' text-anchor='middle'>{safe_title}</text>" \
        f"<text x='50%' y='60%' fill='lime' font-size='{int(min(w,h)*0.035)}' font-family='Arial' text-anchor='middle'>{subtitle}</text></svg>"
    return s

@app.post("/social/export")
def social_export():
    body=request.get_json(silent=True) or {}
    pub_id=body.get("publish_id"); channels=body.get("channels",["shorts","tiktok","instagram"])
    folder=_pub_folder(pub_id); post=json.load(open(os.path.join(folder,"post.json")))
    title=post["seed"].get("title","Untitled"); mood=post["seed"].get("mood","neutral")
    base=os.path.join(folder,"social"); pathlib.Path(base).mkdir(parents=True, exist_ok=True)
    outputs=[]
    for ch in channels:
        ch_dir=os.path.join(base,ch); pathlib.Path(ch_dir).mkdir(parents=True, exist_ok=True)
        if ch in ("shorts","tiktok"): w,h=1080,1920
        elif ch=="instagram": w,h=1080,1350
        else: w,h=1024,576
        svg=_svg_cover(w,h,title,f"mood: {mood} • {ch}")
        cover=os.path.join(ch_dir,"cover.svg"); open(cover,"w").write(svg)
        meta={"channel":ch,"title":title,"caption":f"{title} — mood: {mood}","hashtags":["#art","#fashion","#ai","#critique"]}
        open(os.path.join(ch_dir,"meta.json"),"w").write(json.dumps(meta,indent=2))
        outputs.append({"channel":ch,"cover":cover,"meta":os.path.join(ch_dir,"meta.json")})
    return jsonify({"status":"SOCIAL_OK","publish_id":pub_id,"outputs":outputs})

@app.post("/pack/export")
def pack_export():
    body=request.get_json(silent=True) or {}
    pub_id=body.get("publish_id")
    folder=_pub_folder(pub_id)
    outdir=os.path.join(PUB,"exports"); pathlib.Path(outdir).mkdir(parents=True, exist_ok=True)
    zip_path=os.path.join(outdir, f"{pub_id}.zip")
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for root,_,files in os.walk(folder):
            for name in files:
                fp=os.path.join(root,name); rel=os.path.relpath(fp, folder)
                z.write(fp, arcname=rel)
    return jsonify({"status":"EXPORTED","zip_path":zip_path,"download":f"/publish/export/{pub_id}.zip"})

@app.get("/publish/export/<pub_id>.zip")
def export_download(pub_id):
    path=os.path.join(PUB,"exports",f"{pub_id}.zip")
    if not os.path.exists(path): return Response("Not found",status=404)
    return send_file(path, as_attachment=True)

# ---------- NEW: Dashboard + Healthz ----------
@app.get("/dashboard")
def dashboard():
    last = open(os.path.join(PUB,"last.txt")).read().strip() if os.path.exists(os.path.join(PUB,"last.txt")) else ""
    body = ["<h1>PhiANDO — Dashboard</h1>"]
    if not last:
        body.append("<p>No publish yet.</p>")
    else:
        folder=os.path.join(PUB,last)
        body.append(f"<p>Last publish: <b>{last}</b></p>")
        if os.path.isdir(folder):
            files=[]
            for root,_,fs in os.walk(folder):
                for name in fs:
                    p=os.path.join(root,name)
                    rel=os.path.relpath(p, folder)
                    if name=="index.html":
                        files.append(f"<li><a href='/publish/view/{last}'>index.html (view)</a></li>")
                    else:
                        files.append(f"<li>{rel}</li>")
            body.append("<ul>"+ "\n".join(sorted(set(files))) +"</ul>")
    html="<html><head><meta charset='utf-8'><style>body{font-family:system-ui;background:#111;color:#eee;padding:24px}a{color:#8ef}</style></head><body>"+ "\n".join(body) +"</body></html>"
    return Response(html, mimetype="text/html")

@app.get("/healthz")
def healthz():
    ok = os.path.exists(os.path.join(PUB,"last.txt"))
    return jsonify({"ok": ok, "time": int(time.time()), "version": "V4.4"})
