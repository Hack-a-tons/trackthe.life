# TODO — staged MVP plan

This plan follows the order you specified.

---

## 0. Repo + scaffolding
- [ ] Create Node.js project (`npm init -y`)
- [ ] Add deps: `express`, `multer`, `dotenv`, `axios`, `node-fetch` (or `undici`), maybe `ffmpeg-static`, `fluent-ffmpeg`
- [ ] Add linting + `scripts/` folder for bash demos
- [ ] Add `docker-compose.yml` for local ApertureDB + MemMachine (both give Docker options) and Node.js
- [ ] Add `.env.example` with all service URLs

---

## 1. ESP web cam (Wi‑Fi connection for the moment)
- [ ] Open Freenove tutorial, Chapter 34 “Camera Web Server” and 35 “Camera TCP Server”, build and flash the example. fileciteturn0file0
- [ ] Hardcode Wi‑Fi SSID/PASS for local network
- [ ] Confirm stream reachable from laptop (MJPEG page or single‑frame snapshot)
- [ ] Write `scripts/pull_frame.sh` to curl the ESP snapshot endpoint and save to `captures/` locally
- [ ] (Optional) autosave every N seconds via cron

---

## 2. Upload to ApertureDB / recognize and describe
- [ ] Start ApertureDB locally (see vendor docs). fileciteturn0file2
- [ ] In Node.js, build `/api/media` endpoint that takes `multipart/form-data` with `file`, `user_id`, `timestamp`, `location?`
- [ ] On upload: call ApertureDB REST/gRPC to create an Image/Video object + store attributes
- [ ] Trigger ApertureDB workflow to run detection/description (faces, objects) — store returned labels in same record. fileciteturn0file2
- [ ] Write `scripts/upload_frame.sh` that POSTs an image from `captures/` to the endpoint
- [ ] Log the whole pipeline to Comet/Opik (one trace per upload). fileciteturn0file1

---

## 3. Integrate MemMachine / store all findings
- [ ] Run MemMachine with docker (`docker-compose up -d`) per their README. fileciteturn0file4
- [ ] In Node.js, after a successful ApertureDB insert, call MemMachine REST to write an episodic memory:
      “user: X, time: T, media_id: Y, labels: […], location: L”
- [ ] Also store profile-level info when available (e.g. frequent locations)
- [ ] Make a tiny helper `memmachineClient.js` so the rest of the code stays clean

---

## 4. Integrate speech recognition from Telnyx
- [ ] From Flutter (or as separate CLI), record a small `.m4a` or `.wav`
- [ ] Add Node.js endpoint `/api/audio` that accepts audio and forwards it to Telnyx
- [ ] Call `https://api.telnyx.com/v2/ai/audio/transcriptions` with `multipart/form-data` and `Authorization: Bearer $TELNYX_API_KEY` and selected model. fileciteturn0file3
- [ ] Store transcription text + timestamps and link to the same media object in ApertureDB
- [ ] Also mirror transcription into MemMachine as text memory (“user said … at time …”)
- [ ] Add `scripts/upload_audio.sh` for demo

---

## 5. Make Flutter app to visualize everything
- [ ] Flutter project `lifestream_app`
- [ ] Screens:
    - [ ] Login / choose user
    - [ ] “Timeline” — list uploads (thumbnail, time, location, labels)
    - [ ] Detail page — video player + transcript
- [ ] REST calls to Node.js to list media + transcripts
- [ ] Map widget (later) to show GPS from phone

---

## 6. Create the part which will produce clips etc.
- [ ] Add Node.js script `scripts/build_daily_clip.js`:
    - query ApertureDB for media in last 24h
    - rank by: has people, has speech, is moving, has known location
    - produce JSON EDL
    - run FFmpeg to stitch
- [ ] Add `scripts/build_weekly_clip.js` that just stitches daily ones
- [ ] Store produced clips back in ApertureDB / S3
- [ ] Log clip building runs to Comet/Opik for quality comparison. fileciteturn0file1

---

## 7. Everything else afterwards (post‑MVP plan)
- [ ] ESP32 audio via I2S mic (true on‑device audio)
- [ ] BLE/Wi‑Fi Direct from ESP to phone
- [ ] On‑device event detection (motion, face)
- [ ] Social layer — cross‑user event matching (“same place/time → merge clips”)
- [ ] Identity / auth (Cognito/Auth0)
- [ ] Cost optimization and cloud buckets
- [ ] Export to external editors

---

## Bash scripts to include now

- [ ] `scripts/pull_frame.sh` — download from ESP
- [ ] `scripts/upload_frame.sh` — send to backend
- [ ] `scripts/upload_audio.sh` — send to backend → Telnyx
- [ ] `scripts/build_daily_clip.sh` — call Node.js script
- [ ] All scripts start with:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

---

## Notes on hardware limits
- Freenove ESP32 kit shows how to run camera over Wi‑Fi, SD card, and TCP server — reuse those. GPS is **not** in the kit, so the phone must supply it. fileciteturn0file0
