#!/usr/bin/env python3
import argparse, os, sys, time, json, pathlib
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]

BASE = os.path.expanduser("~/ANGELADOLORES")
SECRET_DIR = os.path.join(BASE, "secret")
CLIENT = os.path.join(SECRET_DIR, "client_secret.json")
TOKEN  = os.path.join(SECRET_DIR, "token.json")

def get_service():
    creds = None
    if os.path.exists(TOKEN):
        creds = Credentials.from_authorized_user_file(TOKEN, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CLIENT):
                sys.exit("[!] Missing client_secret.json in ~/ANGELADOLORES/secret/")
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT, SCOPES)
            creds = flow.run_local_server(port=0, prompt="consent")
        with open(TOKEN, "w") as f: f.write(creds.to_json())
    return build("youtube","v3", credentials=creds)

def upload(video_path, title, description, tags, privacy, category, made_for_kids, publish_at):
    service = get_service()
    body = {
        "snippet": {
            "title": title[:100],
            "description": description[:5000],
            "tags": [t.strip() for t in (tags or "").split(",") if t.strip()],
            "categoryId": str(category),
        },
        "status": {
            "privacyStatus": privacy,
            "selfDeclaredMadeForKids": bool(made_for_kids),
        },
    }
    if publish_at:
        body["status"]["privacyStatus"] = "private"
        body["status"]["publishAt"] = publish_at  # RFC3339

    media = MediaFileUpload(video_path, chunksize=4*1024*1024, resumable=True)
    request = service.videos().insert(part="snippet,status", body=body, media_body=media)
    response = None
    retry = 0
    while response is None:
        try:
            status, response = request.next_chunk()
            if status and status.total_size:
                pct = int(status.progress() * 100)
                print(f"[PROGRESS] {pct}%")
        except Exception as e:
            retry += 1
            if retry > 5:
                raise
            time.sleep(2 * retry)
            print(f"[RETRY] {retry} after error: {e}")
    vid = response["id"]
    print(f"[OK] videoId={vid}")
    return vid

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--description", default="")
    ap.add_argument("--tags", default="")
    ap.add_argument("--privacy", default="unlisted", choices=["public","unlisted","private"])
    ap.add_argument("--category", type=int, default=24)  # Entertainment
    ap.add_argument("--kids", action="store_true")
    ap.add_argument("--publish_at", default="")  # e.g., 2025-10-22T20:00:00Z
    args = ap.parse_args()
    vid = upload(args.file, args.title, args.description, args.tags, args.privacy, args.category, args.kids, args.publish_at or None)
    print(vid)
if __name__ == "__main__": main()
