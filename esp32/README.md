# ESP32 Camera Setup for trackthe.life

This guide explains how to flash and configure the ESP32-WROVER camera module for the trackthe.life lifelogging system.

## Hardware Requirements

- **Freenove ESP32-WROVER Kit** with camera module
- USB cable for programming
- Computer with Arduino IDE

## Software Requirements

- **Arduino IDE** 1.8.19 or later (or Arduino IDE 2.x)
- **ESP32 Board Support** installed in Arduino IDE

---

## Installation Steps

### 1. Install Arduino IDE

Download from: https://www.arduino.cc/en/software

### 2. Add ESP32 Board Support

1. Open Arduino IDE
2. Go to **File → Preferences**
3. In "Additional Board Manager URLs", add:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Click **OK**
5. Go to **Tools → Board → Boards Manager**
6. Search for "esp32"
7. Install **"esp32 by Espressif Systems"** (version 2.0.11 or later)

### 3. Configure Board Settings

1. Go to **Tools → Board → ESP32 Arduino**
2. Select **"ESP32 Wrover Module"**
3. Configure settings:
   - **Upload Speed**: 115200
   - **Flash Frequency**: 80MHz
   - **Flash Mode**: QIO
   - **Partition Scheme**: Huge APP (3MB No OTA/1MB SPIFFS)
   - **Core Debug Level**: None
   - **PSRAM**: Enabled

### 4. Configure WiFi and Backend

1. Open `esp32/trackthelife_camera/wifi_config.h`
2. Update the following settings:

```cpp
// WiFi credentials (already set)
const char *WIFI_SSID = "Guest";
const char *WIFI_PASSWORD = "BrokenWires@@2019";

// Backend server - CHANGE THIS to your laptop's IP
const char *BACKEND_HOST = "192.168.1.100";  // ← Find your IP with: ifconfig | grep inet
const int BACKEND_PORT = 4000;

// Device ID (optional - change if you have multiple cameras)
const char *USER_ID = "esp32-cam-01";

// Capture interval (milliseconds)
const unsigned long CAPTURE_INTERVAL_MS = 5000;  // 5 seconds
```

**To find your laptop's IP address:**

macOS/Linux:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

The IP will look like `192.168.1.xxx` or `10.0.0.xxx`

### 5. Upload the Sketch

1. Connect ESP32 to your computer via USB
2. In Arduino IDE, go to **Tools → Port** and select the ESP32 port
   - macOS: `/dev/cu.usbserial-xxxxx` or `/dev/cu.SLAB_USBtoUART`
   - Windows: `COM3`, `COM4`, etc.
3. Open `esp32/trackthelife_camera/trackthelife_camera.ino`
4. Click **Upload** button (→)
5. Wait for compilation and upload (takes 1-2 minutes)

### 6. Monitor Serial Output

1. After upload, open **Tools → Serial Monitor**
2. Set baud rate to **115200**
3. You should see:
   ```
   === trackthe.life Camera Starting ===
   Initializing camera...
   Camera initialized
   Connecting to WiFi: Guest
   ....
   WiFi connected!
   IP: 192.168.1.xxx
   === Setup Complete ===
   Capturing every 5000 ms
   Capturing frame...
   Frame captured: 45678 bytes
   Upload response: 200
   Response: {"status":"ok","media_id":"mock_...","labels":[...]}
   ```

---

## Troubleshooting

### Camera Init Failed
- **Check board selection**: Must be "ESP32 Wrover Module"
- **Check PSRAM**: Must be enabled in Tools menu
- **Check partition scheme**: Use "Huge APP (3MB No OTA/1MB SPIFFS)"

### WiFi Connection Failed
- Verify SSID and password in `wifi_config.h`
- Check that WiFi network is 2.4GHz (ESP32 doesn't support 5GHz)
- Move ESP32 closer to router

### Upload Failed
- Check USB cable (must support data, not just power)
- Try different USB port
- Press and hold BOOT button on ESP32 during upload
- Reduce upload speed: Tools → Upload Speed → 115200

### Backend Connection Failed
- Verify backend server is running: `npm start`
- Check BACKEND_HOST IP is correct
- Ensure laptop and ESP32 are on same network
- Test backend: `curl http://localhost:4000/api/health`

---

## Features

### Current Implementation

- **Auto-capture**: Takes photos every 5 seconds (configurable)
- **Auto-upload**: Sends JPEG frames to Node.js backend via HTTP POST
- **WiFi reconnection**: Automatically reconnects if connection drops
- **Serial logging**: Detailed debug output for monitoring

### Frame Settings

- **Resolution**: SVGA (800x600) - good balance of quality and size
- **Format**: JPEG
- **Quality**: 12 (0-63 scale, lower = better quality)
- **Typical size**: 30-60 KB per frame

### Customization

Edit `wifi_config.h` to change:
- Capture interval (default: 5 seconds)
- Device ID
- Backend endpoint

Edit `trackthelife_camera.ino` to change:
- Frame resolution (line 52): `FRAMESIZE_SVGA`, `FRAMESIZE_VGA`, `FRAMESIZE_QVGA`
- JPEG quality (line 56): 10-15 recommended (lower = better)
- Camera settings (brightness, saturation, etc.)

---

## Video Streaming (Future)

The current implementation captures **individual frames**. For continuous video streaming:

1. ESP32 can serve MJPEG stream (series of JPEG frames)
2. Backend would need to:
   - Accept streaming endpoint
   - Buffer frames
   - Assemble into video segments
3. Higher bandwidth and processing requirements

**Recommendation**: Start with frame capture (current implementation), add streaming later if needed.

---

## Architecture Decision: Why Node.js Intermediary?

We use **Node.js backend as intermediary** instead of direct ApertureDB upload because:

1. **ESP32 limitations**:
   - Limited RAM (520KB)
   - Simple HTTP client
   - No retry logic
   - No authentication handling

2. **Backend benefits**:
   - Handles ApertureDB, MemMachine, Telnyx, Comet orchestration
   - Adds metadata (timestamps, location from phone)
   - Implements retry and error handling
   - Logs and monitors all uploads
   - Can batch/buffer frames

3. **Flexibility**:
   - Change services without reflashing ESP32
   - Add preprocessing (resize, compress)
   - Merge with phone audio/GPS data

---

## Next Steps

1. Flash ESP32 with this sketch
2. Start backend: `npm start`
3. Monitor serial output to verify captures
4. Check backend logs for received frames
5. Test with: `curl http://localhost:4000/api/health`

For pull-based capture (instead of auto-upload), see `scripts/pull_frame.sh` (requires web server mode).
