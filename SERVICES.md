# Service Usage Summary

## ✅ ACTIVE SERVICES

### MemMachine
**Status:** ✅ ACTIVE  
**Purpose:** Episodic memory storage and retrieval  
**Usage:**
- Stores every media upload as a memory with full context
- Memory format: `"User {user_id} captured {image/video} at {timestamp}: '{description}'. Audio: '{transcription}' at GPS location {coords} from {city}, {region}, {country}"`
- Links visual analysis + audio transcription + location in single memory
- Enables semantic search across all captured moments
- Used in: `/api/media` (write), `/api/memories` (read)

**Configuration:**
```env
MEMMACHINE_URL=http://localhost:7860
MEMMACHINE_API_KEY=changeme
```

### Azure Computer Vision
**Status:** ✅ ACTIVE (replacing ApertureDB)  
**Purpose:** Image and video frame analysis  
**Usage:**
- Analyzes images for: description, tags, objects, faces, categories, colors
- Extracts first frame from videos for visual analysis
- Provides detailed descriptions: "a person riding a skateboard. 1 person detected. Objects: person (95%), skateboard (87%). Colors: black, gray, white"
- Returns confidence scores and bounding boxes
- Used in: `aperturedbClient.js` (analyzeImage, analyzeVideo)

**Configuration:**
```env
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_API_KEY=your-key
```

**API Endpoint:**
```
POST {endpoint}/vision/v3.2/analyze?visualFeatures=Description,Tags,Objects,Faces,Categories,Color,ImageType&details=Celebrities,Landmarks
```

### Azure OpenAI Whisper
**Status:** ✅ ACTIVE (replacing Telnyx)  
**Purpose:** Audio transcription from uploaded audio files and video soundtracks  
**Usage:**
- Transcribes audio files uploaded via `/api/audio`
- Extracts and transcribes audio from video files automatically
- Returns text + timestamps for semantic search
- Links transcription to visual analysis in MemMachine
- Used in: `telnyxClient.js` (transcribe), `media.js` (video audio)

**Configuration:**
```env
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_API_KEY=your-key
```

**API Endpoint:**
```
POST {endpoint}/openai/deployments/whisper/audio/transcriptions?api-version=2024-02-01
```

### Comet / Opik
**Status:** ✅ ACTIVE  
**Purpose:** Experiment tracking and LLM observability  
**Usage:**
- Logs every media upload with metadata: duration, media_id, user_id, has_gps, has_ip_location, has_transcription, is_video
- Tracks API performance and success rates
- Enables A/B testing of different AI models
- Used in: `cometClient.js`, all route handlers

**Configuration:**
```env
COMET_API_KEY=your-key
COMET_WORKSPACE=your-workspace
```

### IP Geolocation (ip-api.com)
**Status:** ✅ ACTIVE  
**Purpose:** Fallback location when GPS unavailable  
**Usage:**
- Looks up client IP to get city, region, country, lat/lon
- Used when mobile app doesn't provide GPS coordinates
- Free tier: 45 requests/minute
- Used in: `geoipClient.js`, `media.js`

**API Endpoint:**
```
GET http://ip-api.com/json/{ip}
```

### FFmpeg
**Status:** ✅ ACTIVE  
**Purpose:** Video processing  
**Usage:**
- Extracts first frame from videos for visual analysis
- Extracts audio track from videos for transcription
- Converts video formats if needed
- Used in: `aperturedbClient.js` (extractVideoFrame, extractVideoAudio)

**Commands:**
```bash
# Extract frame
ffmpeg -i video.mp4 -vframes 1 -f image2 frame.jpg -y

# Extract audio
ffmpeg -i video.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav -y
```

---

## ❌ NOT USED / REPLACED

### ApertureDB
**Status:** ❌ REPLACED by Azure Computer Vision  
**Reason:** Cloud instance API down (502 Bad Gateway), web UI works but backend unavailable  
**Original Purpose:** Multimodal database for images, videos, embeddings, and metadata  
**Replacement:** Azure Computer Vision for analysis + local file storage in `/app/uploads/`

**What we lost:**
- Vector similarity search across images
- Built-in object detection and tracking
- Temporal queries across video segments

**What we gained:**
- More detailed natural language descriptions
- Face detection with demographics
- Celebrity and landmark recognition
- Color analysis
- Higher reliability (Azure SLA)

### Telnyx
**Status:** ❌ REPLACED by Azure OpenAI Whisper  
**Reason:** Model `whisper-large-v3` doesn't exist in Telnyx API  
**Original Purpose:** Audio transcription via OpenAI-compatible endpoint  
**Replacement:** Azure OpenAI Whisper deployment

**What we lost:**
- Nothing significant

**What we gained:**
- Same Whisper model, better integration
- Already had Azure credentials configured
- More reliable API

---

## Architecture Flow

```
┌─────────────────┐
│  ESP32 Camera   │
│  Flutter App    │
└────────┬────────┘
         │ POST /api/media
         ▼
┌─────────────────────────────────────────────────────────┐
│                    Node.js Backend                       │
│                                                          │
│  1. Receive file (image/video)                          │
│  2. Get IP → ip-api.com → location fallback             │
│  3. Store file → /app/uploads/                          │
│  4. If video:                                           │
│     a. FFmpeg extract frame → Azure Computer Vision     │
│     b. FFmpeg extract audio → Azure Whisper             │
│  5. If image:                                           │
│     a. Azure Computer Vision → detailed description     │
│  6. Build memory text:                                  │
│     "User X captured video: 'description'. Audio:       │
│      'transcription' at location Y"                     │
│  7. MemMachine.addMemory() → store episodic memory      │
│  8. Comet.logTrace() → track metrics                    │
│  9. Return JSON with description, transcription, etc.   │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Flutter App    │
│  Display results│
└─────────────────┘
```

---

## Cost Analysis

| Service | Tier | Cost | Usage |
|---------|------|------|-------|
| MemMachine | Cloud | Free beta | ~100 memories/day |
| Azure Computer Vision | Standard | $1/1000 calls | ~50 images/day = $0.05/day |
| Azure OpenAI Whisper | Standard | $0.006/min | ~10 min/day = $0.06/day |
| Comet | Free | $0 | Unlimited traces |
| ip-api.com | Free | $0 | <45 req/min |
| FFmpeg | Open source | $0 | Local processing |

**Total:** ~$3.30/month for 50 media uploads/day

---

## Future Considerations

### If ApertureDB comes back online:
- Could use for vector similarity search: "find all images similar to this one"
- Temporal queries: "show me all videos from last Tuesday"
- Object tracking across video frames
- Spatial queries: "find all images within 1km of this location"

### If we need more scale:
- Azure Cognitive Services batch processing
- S3 for media storage instead of local disk
- Redis for caching analysis results
- PostgreSQL for structured metadata

### If we add more AI features:
- Azure Custom Vision for person recognition
- Azure Speech for real-time transcription
- GPT-4 Vision for complex scene understanding
- Ollama for local LLM processing (privacy mode)
