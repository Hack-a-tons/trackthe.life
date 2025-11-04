# TODO — staged MVP plan

This plan follows the order you specified.

---

## 0. Repo + scaffolding
- [x] Create Node.js project (`npm init -y`)
- [x] Add deps: `express`, `multer`, `dotenv`, `axios`, `node-fetch` (or `undici`), maybe `ffmpeg-static`, `fluent-ffmpeg`
- [x] Add linting + `scripts/` folder for bash demos
- [x] Add `docker-compose.yml` for local ApertureDB + MemMachine (both give Docker options) and Node.js
- [x] Add `.env.example` with all service URLs

---

## 1. ESP web cam (Wi‑Fi connection for the moment)
- [x] Open Freenove tutorial, Chapter 34 “Camera Web Server” and 35 “Camera TCP Server”, build and flash the example. 
- [x] Hardcode Wi‑Fi SSID/PASS for local network
- [x] Confirm stream reachable from laptop (MJPEG page or single‑frame snapshot)
- [x] Write `scripts/pull_frame.sh` to curl the ESP snapshot endpoint and save to `captures/` locally
- [ ] (Optional) autosave every N seconds via cron

---

## 2. Upload to ApertureDB / recognize and describe
- [x] Start ApertureDB locally (see vendor docs). 
- [x] In Node.js, build `/api/media` endpoint that takes `multipart/form-data` with `file`, `user_id`, `timestamp`, `location?`
- [x] On upload: call ApertureDB REST/gRPC to create an Image/Video object + store attributes
- [x] Trigger ApertureDB workflow to run detection/description (faces, objects) — store returned labels in same record. 
- [x] Write `scripts/upload_frame.sh` that POSTs an image from `captures/` to the endpoint
- [x] Log the whole pipeline to Comet/Opik (one trace per upload). 

---

## 3. Integrate MemMachine / store all findings
- [x] Run MemMachine with docker (`docker-compose up -d`) per their README. 
- [x] In Node.js, after a successful ApertureDB insert, call MemMachine REST to write an episodic memory:
      “user: X, time: T, media_id: Y, labels: […], location: L”
- [x] Also store profile-level info when available (e.g. frequent locations)
- [x] Make a tiny helper `memmachineClient.js` so the rest of the code stays clean

---

## 4. Integrate speech recognition from Telnyx
- [x] From Flutter (or as separate CLI), record a small `.m4a` or `.wav`
- [x] Add Node.js endpoint `/api/audio` that accepts audio and forwards it to Telnyx
- [x] Call `https://api.telnyx.com/v2/ai/audio/transcriptions` with `multipart/form-data` and `Authorization: Bearer $TELNYX_API_KEY` and selected model. 
- [x] Store transcription text + timestamps and link to the same media object in ApertureDB
- [x] Also mirror transcription into MemMachine as text memory (“user said … at time …”)
- [x] Add `scripts/upload_audio.sh` for demo

---

## 5. Make Flutter app to visualize everything
- [ ] Flutter project `trackthelife_app`
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
- [ ] Log clip building runs to Comet/Opik for quality comparison. 

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
- Freenove ESP32 kit shows how to run camera over Wi‑Fi, SD card, and TCP server — reuse those. GPS is **not** in the kit, so the phone must supply it. 
