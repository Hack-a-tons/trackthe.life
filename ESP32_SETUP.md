# ESP32 Camera Setup Guide

## Hardware Requirements

- Freenove ESP32-WROVER CAM Board
- USB cable for programming
- Wi-Fi network access

## Software Setup

### 1. Install Arduino IDE

Download from: https://www.arduino.cc/en/software

### 2. Add ESP32 Board Support

1. Open Arduino IDE
2. Go to File → Preferences
3. Add to "Additional Board Manager URLs":
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Go to Tools → Board → Boards Manager
5. Search for "esp32" and install "ESP32 by Espressif Systems"

### 3. Flash Camera Web Server

1. Open File → Examples → ESP32 → Camera → CameraWebServer
2. Select board: Tools → Board → ESP32 Arduino → ESP32 Wrover Module
3. Configure in code:
   ```cpp
   // WiFi credentials
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   
   // Camera model
   #define CAMERA_MODEL_WROVER_KIT
   ```
4. Upload to ESP32
5. Open Serial Monitor (115200 baud) to see IP address

### 4. Test Camera

1. Note the IP address from Serial Monitor (e.g., `192.168.1.100`)
2. Open browser: `http://192.168.1.100`
3. Click "Start Stream" to verify camera works
4. Test capture: `http://192.168.1.100/capture`

## Integration with trackthe.life

### Using Demo Script

```bash
# Run with real ESP32
./demo.sh --esp32-url http://192.168.1.100 all

# Or set environment variable
export ESP32_URL=http://192.168.1.100
./demo.sh --no-emulate-esp32 all
```

### Direct API Call

```bash
# Capture and upload from ESP32
curl -X POST "https://trackthelife.hurated.com/api/media" \
  -F "file=@$(curl -s http://192.168.1.100/capture -o /tmp/esp32.jpg && echo /tmp/esp32.jpg)" \
  -F "user_id=esp32-user" \
  -F "timestamp=$(date -Iseconds)" \
  -F "latitude=37.7749" \
  -F "longitude=-122.4194"
```

## Continuous Capture Mode

Create a script to capture every N seconds:

```bash
#!/usr/bin/env bash
ESP32_URL="http://192.168.1.100"
BACKEND_URL="https://trackthelife.hurated.com"
INTERVAL=30  # seconds

while true; do
  echo "Capturing from ESP32..."
  curl -s "${ESP32_URL}/capture" -o /tmp/esp32_capture.jpg
  
  echo "Uploading to backend..."
  curl -X POST "${BACKEND_URL}/api/media" \
    -F "file=@/tmp/esp32_capture.jpg" \
    -F "user_id=esp32-continuous" \
    -F "timestamp=$(date -Iseconds)"
  
  echo "Waiting ${INTERVAL} seconds..."
  sleep $INTERVAL
done
```

## Troubleshooting

### ESP32 Not Connecting to WiFi
- Check SSID and password
- Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz)
- Check Serial Monitor for error messages

### Camera Not Working
- Verify camera model in code matches hardware
- Check camera ribbon cable connection
- Try power cycling the ESP32

### Can't Access Web Interface
- Ensure ESP32 and computer on same network
- Check firewall settings
- Try accessing from phone on same WiFi

## Advanced: Motion Detection

Add motion detection on ESP32:

```cpp
// In loop()
if (motionDetected()) {
  captureAndUpload();
}
```

## Power Optimization

For battery operation:
- Use deep sleep between captures
- Reduce capture frequency
- Lower image resolution
- Disable WiFi when not uploading

## Next Steps

1. Flash ESP32 with camera web server
2. Test capture endpoint
3. Run demo with real ESP32
4. Set up continuous capture
5. Add motion detection (optional)
6. Optimize for battery (optional)
