#!/usr/bin/env python3
import time, os, json, datetime
import sys
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGS = os.path.join(BASE, "logs")
DATA = os.path.join(BASE, "data")
os.makedirs(LOGS, exist_ok=True)
os.makedirs(DATA, exist_ok=True)
print("Heartbeat started...")
i = 0
try:
    while True:
        now = datetime.datetime.now().isoformat()
        hb = {"time": now, "note": f"heartbeat {i}", "pid": os.getpid()}
        log_file = os.path.join(LOGS, f"heartbeat_{int(time.time())}_{i}.json")
        with open(log_file, "w") as f:
            json.dump(hb, f, indent=2)
        print(f"Beat {i} at {now}")
        i += 1
        time.sleep(60)
except KeyboardInterrupt:
    sys.exit(0)
