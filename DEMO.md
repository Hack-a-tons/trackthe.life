# Demo Guide

## Quick Start

```bash
# Start backend first
npm start

# In another terminal, run demo
./demo.sh -p5 all
```

---

## Demo Script Features

### Interactive Workflow
The demo script walks through the complete trackthe.life workflow:

1. **Health Check** - Verify backend is running
2. **Image Upload** - Simulate ESP32 camera capture
3. **Audio Upload** - Simulate phone audio transcription
4. **Memory Query** - Show MemMachine integration
5. **Summary** - Display complete data flow

### Command Line Options

**Pause Control**:
```bash
./demo.sh -p all           # Wait for keypress after each step
./demo.sh -p5 all          # Pause 5 seconds between steps
./demo.sh --pause 30 all   # Pause 30 seconds between steps
```

**Verbose Mode**:
```bash
./demo.sh -v all           # Show curl commands and JSON responses
./demo.sh --verbose all    # Same as -v
```

**Combined Options**:
```bash
./demo.sh -vp5 all         # Verbose + 5 second pause
./demo.sh -p --verbose all # Keypress pause + verbose
```

**Individual Steps**:
```bash
./demo.sh health           # Just health check
./demo.sh upload-image     # Just image upload
./demo.sh upload-audio     # Just audio upload
./demo.sh query-memories   # Just memory query
./demo.sh summary          # Just summary
```

---

## Demo Workflow Explained

### Step 1: Health Check
Verifies the Node.js backend is running and all services are configured.

**What it does**:
- Calls `GET /api/health`
- Checks for `status: ok`
- Lists configured services

**Expected output**:
```
✓ Backend is healthy!
services:[ApertureDB, MemMachine, Telnyx, Comet]
```

### Step 2: Image Upload (ESP32 Simulation)
Simulates an ESP32 camera capturing and uploading a frame.

**What it does**:
- Creates test image (if needed)
- Calls `POST /api/media` with multipart form data
- Includes user_id, timestamp, location

**Data flow**:
```
Test Image → Node.js Backend → ApertureDB (object detection)
                             → MemMachine (episodic memory)
                             → Comet (logging)
```

**Expected output**:
```
✓ Image uploaded successfully!
  Media ID: mock_1730761234567
  Detected: ["mock_label"]
```

### Step 3: Audio Upload (Phone Simulation)
Simulates phone audio being sent for transcription.

**What it does**:
- Creates test audio file (if needed)
- Calls `POST /api/audio` with audio data
- Triggers Telnyx speech-to-text

**Data flow**:
```
Test Audio → Node.js Backend → Telnyx (transcription)
                             → MemMachine (text memory)
                             → Comet (logging)
```

**Expected output**:
```
✓ Audio transcribed successfully!
  Transcription: Mock transcription: This is a test audio file.
```

### Step 4: Memory Query
Explains how MemMachine stores episodic memories.

**What it stores**:
- User captured media at time/location
- User said specific phrases
- Detected objects and scenes
- Cross-session context

### Step 5: Summary
Shows complete system overview and next steps.

**Displays**:
- What happened in the demo
- Complete data flow diagram
- Next steps for production

---

## Verbose Mode Details

When running with `-v` or `--verbose`, the script shows:

**Curl Commands** (in gray):
```
curl -X POST "http://localhost:4000/api/media" -F "file=@captures/test.jpg" ...
```

**JSON Responses** (in gray):
```json
{
  "status": "ok",
  "media_id": "mock_1730761234567",
  "labels": ["mock_label"]
}
```

This is useful for:
- Debugging API issues
- Understanding request/response format
- Learning the API structure
- Testing with curl directly

---

## Customization

### Change Backend URL
```bash
BACKEND_URL=https://trackthelife.hurated.com ./demo.sh all
```

### Use Real Files
Replace test files in `captures/`:
```bash
# Use your own image
cp my_photo.jpg captures/test.jpg

# Use your own audio
cp my_audio.m4a captures/test.m4a

# Run demo
./demo.sh upload-image upload-audio
```

---

## Troubleshooting

### Backend Not Running
```
✗ Backend health check failed
```
**Solution**: Start backend with `npm start`

### Connection Refused
```
curl: (7) Failed to connect to localhost port 4000
```
**Solution**: Check backend is running on correct port

### Test Files Not Created
The script auto-creates test files in `captures/` directory. If ImageMagick is installed, it creates a real image; otherwise, it creates a text file.

---

## Demo for Presentations

**Recommended flow for demos**:

1. **Quick overview** (no pause):
   ```bash
   ./demo.sh all
   ```

2. **Detailed walkthrough** (with pauses):
   ```bash
   ./demo.sh -p all
   ```

3. **Technical deep-dive** (verbose):
   ```bash
   ./demo.sh -vp all
   ```

4. **Individual feature showcase**:
   ```bash
   ./demo.sh health
   ./demo.sh upload-image
   ./demo.sh upload-audio
   ```

---

## Integration with CI/CD

Use demo script for automated testing:

```bash
# In CI pipeline
npm start &
sleep 5
./demo.sh health || exit 1
./demo.sh upload-image || exit 1
./demo.sh upload-audio || exit 1
```

---

## Next Steps After Demo

1. **Flash ESP32**: See `esp32/README.md`
2. **Configure Services**: See `SERVICES.md`
3. **Deploy**: Run `./deploy.sh`
4. **Monitor**: Check Comet dashboard for traces
