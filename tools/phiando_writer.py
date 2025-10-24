#!/usr/bin/env python3
import os, sys, json, textwrap, time, re
import requests

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY","").strip()
MODEL = os.getenv("OPENAI_MODEL","gpt-4o-mini")
def llm(prompt):
    if not OPENAI_API_KEY:
        return None
    try:
        r = requests.post("https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {OPENAI_API_KEY}","Content-Type":"application/json"},
            json={
                "model": MODEL,
                "temperature": 0.7,
                "messages":[
                    {"role":"system","content":(
                        "You are PHIANDO Writer: a sharp drag-queen critic voice. "
                        "Write in clean English, witty, tight. Output ONLY valid JSON."
                    )},
                    {"role":"user","content": prompt}
                ]
            }, timeout=90)
        r.raise_for_status()
        return r.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"[WRITER:FALLBACK] {e}", file=sys.stderr)
        return None

def fallback(topic, thesis, rule):
    title_variants = [
        f"RuPaul {topic}: {rule}",
        f"{topic} Lessons from RuPaul",
        f"Drag School: {topic} — {rule}",
    ]
    desc = ("A sharp, comedic critique about RuPaul's {topic}. "
            "We unpack how drag meets design, editing, and business. "
            f"Takeaways: {thesis}. Rule: {rule}.").format(topic=topic)
    tags = ["RuPaul","Drag Race","runway","drag critique","creative business","editing","brand",topic]
    chapters = [
        "00:00 Cold Open",
        "00:25 Thesis",
        "01:40 Case Study",
        "03:10 Craft Rule",
        "04:30 Business Note",
        "05:20 Outro"
    ]
    shorts_title = f"Big Stage, Small Budget — {rule}"
    shorts_description = f"30 seconds, one rule: {rule}. Watch the full episode."
    thumb_lines = [rule, thesis, "Cut • Punch • Rhythm"]
    pinned = f"What's YOUR {topic} rule in one line? Best comments featured in S02."
    script_md = textwrap.dedent(f"""\
        # Cold Open
        Darling, if budget was talent, half of you would be billionaires.

        # Thesis
        {thesis}.

        # Case
        {topic} in RuPaul's career arc.

        # Craft Rule
        {rule}.

        # Runway/Challenge Notes
        Silhouette, construction, story beats. If it doesn’t read at 10 meters, it doesn’t exist.

        # Business Note
        Turn one success into a format.

        # Outro
        Don't be expensive—be decisive.
    """)
    return {
        "title_variants": title_variants,
        "description": desc,
        "tags": tags,
        "chapters": chapters,
        "shorts_title": shorts_title,
        "shorts_description": shorts_description,
        "thumb_lines": thumb_lines,
        "pinned_comment": pinned,
        "script_md": script_md
    }

def write_ep(base, handle, ep, topic, thesis, rule):
    root = os.path.join(base,"channel",handle)
    meta = os.path.join(root,"metadata")
    docs = os.path.join(root,"docs")
    caps = os.path.join(root,"captions")
    os.makedirs(meta,exist_ok=True); os.makedirs(docs,exist_ok=True); os.makedirs(caps,exist_ok=True)

    prompt = f"""
Return strict JSON with keys:
title_variants (array of 3), description (string <=600 words),
tags (array <=15), chapters (array 'MM:SS Title' lines),
shorts_title, shorts_description, thumb_lines (array of 3),
pinned_comment, script_md (markdown <= 700 words).
Tone: witty, tight, drag-critic persona. Episode: {ep}.
Topic: "{topic}". Thesis: "{thesis}". Rule: "{rule}".
Avoid brand-new allegations; it's critique & analysis.
"""
    data = None
    txt = llm(prompt)
    if txt:
        try:
            data = json.loads(txt)
        except Exception:
            # try to extract JSON substring
            m = re.search(r"\{.*\}", txt, re.S)
            if m:
                data = json.loads(m.group(0))
    if not data:
        data = fallback(topic, thesis, rule)

    # write files
    def w(p,content):
        with open(p,"w",encoding="utf-8") as f: f.write(content.rstrip()+"\n")

    # meta
    w(os.path.join(meta,f"{ep}_title_variants_en.txt"), "\n".join(data["title_variants"]))
    w(os.path.join(meta,f"{ep}_description_en.txt"), data["description"])
    w(os.path.join(meta,f"{ep}_tags_en.txt"), ", ".join(data["tags"]))
    w(os.path.join(meta,f"{ep}_chapters_en.txt"), "\n".join(data["chapters"]))
    w(os.path.join(meta,f"{ep}_SHORTS_title_en.txt"), data["shorts_title"])
    w(os.path.join(meta,f"{ep}_SHORTS_description_en.txt"), data["shorts_description"])
    w(os.path.join(meta,f"{ep}_thumbnail_lines_en.txt"), "\n".join(data["thumb_lines"]))
    w(os.path.join(meta,f"{ep}_pinned_comment_en.txt"), data["pinned_comment"])
    w(os.path.join(docs,f"{ep}_script_en.md"), data["script_md"])

    # captions template (basic)
    w(os.path.join(caps,f"{ep}_template_en.srt"),
      "1\n00:00:00,000 --> 00:00:03,000\n" +
      data["chapters"][0].split(" ",1)[-1] + "\n\n" +
      "2\n00:00:03,000 --> 00:00:08,000\n" + thesis + "\n"
    )

if __name__=="__main__":
    # args: EP TOPIC THESIS RULE
    ep, topic, thesis, rule = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    write_ep(os.path.expanduser("~/ANGELADOLORES"), "@HellinAssTV", ep, topic, thesis, rule)
    print("[OK] writer updated files for", ep)
