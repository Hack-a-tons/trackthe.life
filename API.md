# trackthe.life — Node.js API Sketch

This document defines the API endpoints for the trackthe.life MVP — the lifelogging and auto-highlights system described in the README.md.  
All endpoints are meant to be simple, RESTful, and ready to test with `curl` or the provided bash scripts.

The backend is written in **Node.js (Express)**, with environment configuration via `.env`.

---

## Base URL

```
http://localhost:4000/api
```

All routes below are prefixed with `/api`.

---

## 1. Media Upload — `/api/media`

### `POST /api/media`

Upload image or short video clip captured by ESP32 or phone.

#### Request (multipart/form-data)
| Field | Type | Required | Description |
|--------|------|-----------|--------------|
| `file` | binary | ✅ | JPEG/MP4 frame or clip |
| `user_id` | string | ✅ | Identifier of user/device |
| `timestamp` | string (ISO 8601) | ✅ | When it was captured |
| `location` | string (lat,lon) | ❌ | Optional GPS from phone |

#### Example
```bash
#!/usr/bin/env bash
curl -X POST "http://localhost:4000/api/media" \
  -F "file=@sample.jpg" \
  -F "user_id=demo" \
  -F "timestamp=$(date -Iseconds)" \
  -F "location=37.4421,-122.1619"
```

#### Behavior
1. Validate inputs.
2. Save temporary file locally or buffer in memory.
3. Send to **ApertureDB**:
   - Create `Video` or `Image` object with metadata.
   - Trigger recognition workflow (faces, objects, scenes).
4. Save returned labels and metadata into local MongoDB/SQLite mirror.
5. Push summary (“user X saw Y at Z”) into **MemMachine**.
6. Log the run to **Comet/Opik** with project name `trackthe.life`.

#### Response
```json
{
  "status": "ok",
  "media_id": "abc123",
  "labels": ["person", "street", "car"]
}
```

---

## 2. Audio Upload / Transcription — `/api/audio`

### `POST /api/audio`

Send audio from phone for transcription.

#### Request (multipart/form-data)
| Field | Type | Required | Description |
|--------|------|-----------|--------------|
| `file` | binary | ✅ | Audio file (.wav, .m4a, .mp3) |
| `user_id` | string | ✅ | Associated user |
| `timestamp` | string (ISO 8601) | ✅ | Capture time |
| `media_id` | string | ❌ | Optional reference to related video |

#### Example
```bash
#!/usr/bin/env bash
curl -X POST "http://localhost:4000/api/audio" \
  -F "file=@voice.m4a" \
  -F "user_id=demo" \
  -F "timestamp=$(date -Iseconds)"
```

#### Behavior
1. Upload file to **Telnyx Speech-to-Text** API (`/v2/ai/audio/transcriptions`).
2. Receive transcription text + timestamps.
3. Store transcript in ApertureDB (attached to related media).
4. Push text memory to **MemMachine**.
5. Log transcription latency & accuracy in **Comet/Opik**.

#### Response
```json
{
  "status": "ok",
  "transcription": "Let's meet at Cafe Venetia at three o'clock.",
  "timestamps": [
    { "word": "Let's", "start": 0.0, "end": 0.2 },
    { "word": "meet", "start": 0.2, "end": 0.5 }
  ]
}
```

---

## 3. Memories — `/api/memories`

### `GET /api/memories?user_id=demo`

Retrieve memory summaries for the given user.

#### Behavior
- Calls **MemMachine** API to retrieve both episodic and semantic memories for user.
- Returns JSON list of memory records with optional embeddings or importance scores.

#### Response
```json
[
  {
    "id": "mem123",
    "timestamp": "2025-11-04T15:12:00Z",
    "summary": "Met with Tomas at Pytheas Energy hackathon.",
    "media_id": "abc123",
    "tags": ["event", "hackathon", "energy"]
  }
]
```

---

## 4. Clips — `/api/clips`

### `POST /api/clips/build`

Trigger highlight video generation for a time window.

#### Request (JSON)
| Field | Type | Required | Description |
|--------|------|-----------|--------------|
| `user_id` | string | ✅ | Whose highlights to build |
| `from` | string | ✅ | Start time (ISO) |
| `to` | string | ✅ | End time (ISO) |
| `granularity` | string | ✅ | `daily`, `weekly`, `monthly` |

#### Behavior
1. Query ApertureDB for all media in the range.
2. Rank them by:
   - Has faces/objects/speech.
   - Engagement (duration, recognitions).
3. Build edit list.
4. Use FFmpeg (via `fluent-ffmpeg`) to concatenate segments.
5. Upload result to ApertureDB (Video object with tag “summary”).
6. Log run to Comet/Opik (“clip_build_duration”, “frames_used”, etc).

#### Response
```json
{
  "status": "ok",
  "clip_id": "clip_2025_11_04_daily",
  "duration": 180,
  "url": "https://aperturedb.local/videos/clip_2025_11_04_daily.mp4"
}
```

---

## 5. Health & Info

### `GET /api/health`
Simple health check to verify backend is alive.

Response:
```json
{ "status": "ok", "services": ["ApertureDB", "MemMachine", "Telnyx", "Comet"] }
```

---

## Example Project Structure

```
/server
 ├── index.js
 ├── routes/
 │    ├── media.js
 │    ├── audio.js
 │    ├── memories.js
 │    ├── clips.js
 │    └── health.js
 ├── services/
 │    ├── aperturedbClient.js
 │    ├── telnyxClient.js
 │    ├── memmachineClient.js
 │    └── cometClient.js
 ├── scripts/
 │    ├── upload_frame.sh
 │    ├── upload_audio.sh
 │    └── build_clip.sh
 ├── .env.example
 └── package.json
```

---

## Required Environment Variables

```env
PORT=4000
APERTUREDB_URL=http://localhost:5555
APERTUREDB_API_KEY=changeme
TELNYX_API_KEY=changeme
MEMMACHINE_URL=http://localhost:7860
MEMMACHINE_API_KEY=changeme
COMET_API_KEY=changeme
COMET_WORKSPACE=trackthelife
```

---

## Next Steps
- Implement each route under `routes/`.
- Add rate limiting / auth (optional for MVP).
- Add logging via `pino` or `winston`.
- Containerize with Docker Compose alongside ApertureDB and MemMachine.
- Write test bash scripts for every endpoint.
