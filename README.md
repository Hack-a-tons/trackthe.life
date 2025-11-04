# trackthe.life

This repository contains the first Proof-of-Concept / MVP for a **lifelogging + auto-highlight generator** inspired by fiction where people have an implanted memory recorder (think *The Final Cut* (2004), the “Grain” from *Black Mirror: The Entire History of You*, or POV-sharing ideas like *Strange Days*). In our case it’s **not** implanted — it’s a small ESP32 camera device + a phone app + AI services.

This MVP is being built as part of **AI Hack Day by Comet at AWS** (see https://luma.com/aws-11-04-25).

The goal:

1. Capture video with an ESP32 (Wi‑Fi for now) and push it to the backend.
2. Store video and multimodal metadata in **ApertureDB** and run recognition on it. 
3. Store conversational / user / agent context in **MemMachine** to make the system “remember” past sessions. 
4. Transcribe audio with **Telnyx Speech‑to‑Text** (OpenAI‑style endpoint) to get text + timestamps. 
5. Instrument the AI parts with **Comet / Opik** for experiment tracking and evaluation. 
6. Visualize everything in a simple **Flutter** app.
7. Auto‑produce daily → weekly → monthly recap clips.

> **Hardware note:** the Freenove ESP32 kit gives us an ESP32‑WROVER and includes camera web server examples over Wi‑Fi, so the *first* step is to make that camera stream/upload. The board itself does **not** have GPS, and in this kit we treat **audio + GPS** as coming from the **phone**. Audio capture on ESP32 is possible with an I2S mic, but that’s outside first MVP scope. 

---

## Architecture (MVP)

**Capture side**
- ESP32 cam (Freenove tutorial → “Camera Web Server”) pushes frames or short clips over Wi‑Fi to a local Node.js endpoint.
- Phone (Flutter app) sends: GPS location, device timestamp, optional local audio chunks.

**Backend (Node.js)**
- Receives media over HTTP (multipart/form-data or simple POST of image/frame).
- Stores raw media and metadata into **ApertureDB** (images, video segments, embeddings, tags). 
- Sends audio files/URLs to **Telnyx** for transcription, stores text + timestamps. 
- Calls **MemMachine** API to persist episodic/profile memories — e.g. “user was at Cafe Venetia 2025‑11‑04 15:10, met person X”. 
- Reports traces / evals to **Comet/Opik** so we can compare recognition pipelines. 

**Client (Flutter)**
- Shows list of captured moments (with thumbnails from ApertureDB).
- Lets user start/stop capture, push audio, and see transcriptions.
- Later: show auto‑generated “daily clip”.

**Clip builder**
- Offline/cron Node.js scripts that:
  1. query ApertureDB for “interesting” events (faces, objects, locations, speech keywords),
  2. fetch associated media segments,
  3. assemble JSON edit decision list (EDL),
  4. run FFmpeg (local) to produce mp4.

---

## Services / Repos

- **ESP32 / Freenove kit** — base firmware from “Camera Web Server” and “Video Web Server” chapters. We only need to tweak Wi‑Fi credentials and upload interval. 
- **Node.js backend** — `express` + a tiny ApertureDB client + Telnyx upload + MemMachine client.
- **ApertureDB** — stores video, images, metadata, and can run recognition workflows. Cloud: https://aperturedata.io or self-hosted. 
- **MemMachine** — universal memory layer; we call it from Node.js to save per‑user context. Cloud: https://memmachine.ai or self-hosted. 
- **Telnyx** — uses OpenAI‑compatible `/v2/ai/audio/transcriptions` to turn audio into text + timestamps. 
- **Comet / Opik** — to log LLM and pipeline runs, and to evaluate ranking of “interesting” events. 

---

## Running order (high level)

1. **ESP web cam** — get the Freenove ESP32 camera web server running and confirm we can pull frames over Wi‑Fi.
2. **Uploader scripts** — bash scripts (`#!/usr/bin/env bash`) that POST captured images/video to the Node.js backend.
3. **Node.js → ApertureDB** — accept upload, create objects, run recognition, store metadata. 
4. **Node.js → MemMachine** — for every uploaded media record a memory “user X at time T did Y at location L”. 
5. **Node.js → Telnyx** — send audio, get text, attach to same media object. 
6. **Flutter app** — list media, show recognized entities, play video.
7. **Clip generator** — Node.js/FFmpeg script that builds daily/weekly recap.

---

## Bash demo scripts

All demo scripts should:
```bash
#!/usr/bin/env bash
set -euo pipefail

# example: upload frame
curl -X POST "http://localhost:4000/api/media" \
  -F "file=@sample.jpg" \
  -F "user_id=demo-user" \
  -F "timestamp=$(date -Iseconds)"
```

Same pattern for: upload audio → backend → Telnyx → store transcript.

---

## Environment

Create `.env`:

```text
PORT=4000
APERTUREDB_URL=http://localhost:5555
APERTUREDB_API_KEY=changeme
TELNYX_API_KEY=changeme
MEMMACHINE_URL=http://localhost:7860
MEMMACHINE_API_KEY=changeme
COMET_API_KEY=changeme
COMET_WORKSPACE=your_workspace
```

No secrets in code — only in `.env`.

---

## Post‑MVP / later

See `TODO.md` for staged development plan.
