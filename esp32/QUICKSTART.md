# ESP32 Quick Start

## TL;DR - 5 Minute Setup

### 1. Find Your Laptop's IP
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Look for: 192.168.x.x or 10.0.x.x
```

### 2. Configure WiFi
```bash
cd esp32/trackthelife_camera
cp wifi_config.h.example wifi_config.h
# Edit wifi_config.h and set BACKEND_HOST to your IP
```

### 3. Arduino IDE Setup
- Install ESP32 board support (see full README.md)
- Select: **Tools → Board → ESP32 Wrover Module**
- Enable: **Tools → PSRAM → Enabled**
- Set: **Tools → Partition Scheme → Huge APP (3MB No OTA)**

### 4. Upload
- Connect ESP32 via USB
- Select port: **Tools → Port → /dev/cu.usbserial-xxxxx**
- Click **Upload** (→)

### 5. Test
```bash
# Terminal 1: Start backend
npm start

# Terminal 2: Monitor ESP32
# Arduino IDE → Tools → Serial Monitor (115200 baud)
# You should see: "Upload response: 200"
```

---

## Configuration Reference

### WiFi Settings (wifi_config.h)
```cpp
const char *WIFI_SSID = "Guest";                    // ✅ Already set
const char *WIFI_PASSWORD = "BrokenWires@@2019";   // ✅ Already set
const char *BACKEND_HOST = "192.168.1.100";        // ⚠️ CHANGE THIS
```

### Capture Settings
```cpp
const unsigned long CAPTURE_INTERVAL_MS = 5000;  // 5 seconds
```

To change interval, edit this value:
- `1000` = 1 second (fast, high bandwidth)
- `5000` = 5 seconds (default, balanced)
- `30000` = 30 seconds (slow, low bandwidth)

---

## Expected Serial Output

```
=== trackthe.life Camera Starting ===
Initializing camera...
Camera initialized
Connecting to WiFi: Guest
.....
WiFi connected!
IP: 192.168.1.123
=== Setup Complete ===
Capturing every 5000 ms
Capturing frame...
Frame captured: 45678 bytes
Upload response: 200
Response: {"status":"ok","media_id":"mock_1730761234567","labels":["mock_label"]}
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| Camera init failed | Enable PSRAM in Tools menu |
| WiFi connection failed | Check SSID/password, use 2.4GHz network |
| Upload failed | Verify backend is running, check IP address |
| Port not found | Install USB driver (CP210x or CH340) |

---

## Architecture

```
ESP32 Camera
    ↓ (HTTP POST every 5s)
Node.js Backend (localhost:4000)
    ↓
ApertureDB + MemMachine + Telnyx + Comet
```

**Why Node.js intermediary?**
- ESP32 has limited memory/processing
- Backend handles service orchestration
- Easier to add logic without reflashing ESP32
- Can merge with phone audio/GPS data

---

## Frame vs Video

**Current**: Individual JPEG frames (30-60 KB each)
- Simpler implementation
- Lower bandwidth
- Good for lifelogging

**Future**: MJPEG streaming
- Continuous video
- Higher bandwidth
- Requires buffering/assembly

Start with frames, add streaming later if needed.

---

For detailed instructions, see [README.md](./README.md)
