# Cloud Services Setup

This guide explains how to set up cloud services for trackthe.life. All services offer cloud/hosted options, so you don't need to run them locally.

---

## 1. ApertureDB (Multimodal Database)

### Cloud Service ✅ Recommended

**Website**: https://aperturedata.io

**Features**:
- Multimodal data storage (images, video, embeddings)
- Built-in object detection and recognition
- Face detection and tracking
- Scene understanding
- Vector similarity search
- Metadata queries

**Setup**:
1. Sign up at https://aperturedata.io
2. Create a new database instance
3. Get credentials from dashboard:
   - **Host Name** (e.g., `your-instance.farm0004.cloud.aperturedata.io`)
   - **Auth Token** (starts with `adbp_`)
4. Update `.env`:
   ```bash
   APERTUREDB_URL=your-instance.farm0004.cloud.aperturedata.io
   APERTUREDB_API_KEY=adbp_your_auth_token_here
   ```

**Note**: Don't include `https://` in the URL - the client adds it automatically.

**Recognition Scenarios**:
- Object detection (people, cars, objects)
- Face recognition and tracking
- Scene classification (indoor/outdoor, location type)
- Activity recognition
- Custom model integration

**Alternative: Self-Hosted**
```bash
docker run -p 5555:5555 aperturedata/aperturedb:latest
APERTUREDB_URL=http://localhost:5555
```

---

## 2. MemMachine (Memory Layer)

### Cloud Service ✅ Recommended

**Website**: https://memmachine.ai  
**GitHub**: https://github.com/MemMachine/MemMachine

**Features**:
- Episodic memory storage
- Semantic memory extraction
- Context-aware retrieval
- User profile building
- Cross-session memory

**Setup**:
1. Sign up at https://memmachine.ai
2. Create API key
3. Update `.env`:
   ```bash
   MEMMACHINE_URL=https://api.memmachine.ai
   MEMMACHINE_API_KEY=your_key_here
   ```

**Alternative: Self-Hosted**
```bash
docker run -p 7860:7860 ghcr.io/memmachine/memmachine:latest
MEMMACHINE_URL=http://localhost:7860
```

---

## 3. Telnyx (Speech-to-Text)

### Cloud Service ✅ Only Option

**Website**: https://portal.telnyx.com

**Features**:
- OpenAI-compatible API
- Multiple Whisper models
- Timestamps per word
- Multiple languages
- High accuracy

**Setup**:
1. Sign up at https://portal.telnyx.com
2. Go to API Keys section
3. Create new API key
4. Update `.env`:
   ```bash
   TELNYX_API_KEY=KEY...your_key_here
   ```

**API Endpoint**: `https://api.telnyx.com/v2/ai/audio/transcriptions`

**Models Available**:
- `whisper-large-v3` (best quality)
- `whisper-medium`
- `whisper-small` (fastest)

---

## 4. Comet/Opik (Experiment Tracking)

### Cloud Service ✅ Recommended

**Website**: https://www.comet.com

**Features**:
- LLM trace logging
- Experiment tracking
- Model evaluation
- Performance metrics
- Team collaboration

**Setup**:
1. Sign up at https://www.comet.com
2. Create workspace
3. Get API key from Settings → API Keys
4. Update `.env`:
   ```bash
   COMET_API_KEY=your_key_here
   COMET_WORKSPACE=trackthelife
   ```

---

## Configuration Summary

### Recommended (All Cloud)

```bash
# .env
PORT=4000
EXTERNAL_PORT=6000
PUBLIC_URL=https://trackthelife.hurated.com

# All cloud services
APERTUREDB_URL=your-instance.farm0004.cloud.aperturedata.io
APERTUREDB_API_KEY=adbp_your_auth_token

TELNYX_API_KEY=your_key

MEMMACHINE_URL=https://api.memmachine.ai
MEMMACHINE_API_KEY=your_key

COMET_API_KEY=your_key
COMET_WORKSPACE=trackthelife
```

### Hybrid (Some Local)

```bash
# Local ApertureDB and MemMachine for development
APERTUREDB_URL=http://localhost:5555
MEMMACHINE_URL=http://localhost:7860

# Cloud for Telnyx and Comet
TELNYX_API_KEY=your_key
COMET_API_KEY=your_key
```

---

## ApertureDB Recognition Scenarios

### 1. Object Detection
```javascript
// Automatically detects objects in images
// Returns: ["person", "car", "tree", "building"]
```

### 2. Face Recognition
```javascript
// Detects and tracks faces across frames
// Can identify known people
// Returns: face bounding boxes, embeddings
```

### 3. Scene Understanding
```javascript
// Classifies scene type
// Returns: "indoor", "outdoor", "office", "street", etc.
```

### 4. Activity Recognition
```javascript
// Detects activities from video
// Returns: "walking", "sitting", "talking", etc.
```

### 5. Custom Queries
```javascript
// Find all frames with:
// - Specific person
// - At specific location
// - With certain objects
// - During time range
```

---

## Cost Considerations

### Free Tiers (as of 2024)

**ApertureDB**: Contact for pricing, may have free tier for hackathons  
**MemMachine**: Free tier available for personal projects  
**Telnyx**: Pay-as-you-go, ~$0.006/minute of audio  
**Comet**: Free tier: 5,000 experiments/month

### Estimated Monthly Cost (Light Usage)

- **ApertureDB**: $0-50 (depending on storage/queries)
- **MemMachine**: $0-20 (free tier likely sufficient)
- **Telnyx**: $5-20 (assuming 1-2 hours audio/day)
- **Comet**: $0 (free tier)

**Total**: ~$5-90/month depending on usage

---

## Local Development Setup

For offline development, use docker-compose:

```bash
# Start local services
docker compose -f docker-compose.dev.yml up -d

# This starts:
# - ApertureDB on localhost:5555
# - MemMachine on localhost:7860
```

Update `.env` to use localhost URLs.

---

## Next Steps

1. **Sign up for services** (start with free tiers)
2. **Get API keys** from each dashboard
3. **Update `.env`** with real credentials
4. **Test connection**:
   ```bash
   npm start
   curl http://localhost:4000/api/health
   ```
5. **Deploy to production**:
   ```bash
   ./deploy.sh
   ```

---

## Support

- **ApertureDB**: https://docs.aperturedata.io
- **MemMachine**: https://github.com/MemMachine/MemMachine/issues
- **Telnyx**: https://developers.telnyx.com
- **Comet**: https://www.comet.com/docs
