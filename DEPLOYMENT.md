# Deployment Guide

## Server Deployment (trackthelife.hurated.com)

### Prerequisites
- Docker and Docker Compose installed on server
- Nginx configured to proxy `https://trackthelife.hurated.com` → `localhost:6000`

### Deploy Steps

1. **SSH to server**:
   ```bash
   ssh trackthelife.hurated.com
   ```

2. **Clone repository**:
   ```bash
   git clone https://github.com/Hack-a-tons/trackthe.life.git
   cd trackthe.life
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with actual API keys
   nano .env
   ```

4. **Build and start**:
   ```bash
   docker compose up -d --build
   ```

5. **Check logs**:
   ```bash
   docker compose logs -f
   ```

6. **Test**:
   ```bash
   curl https://trackthelife.hurated.com/api/health
   ```

### Update Deployment

```bash
cd trackthe.life
git pull
docker compose up -d --build
```

### Stop Service

```bash
docker compose down
```

---

## Port Configuration

- **Internal port**: 4000 (inside container)
- **External port**: 6000 (on host, configured in .env)
- **Public URL**: https://trackthelife.hurated.com (nginx proxy)

Occupied ports on server: 3000, 4000, 5000-5003, 8080, 8888, 50051

---

## ESP32 Configuration

### HTTPS Support

✅ **ESP32 supports HTTPS** with `WiFiClientSecure`

The sketch automatically detects HTTPS URLs and uses secure connection with certificate validation disabled (`.setInsecure()`).

### Production URL

```cpp
const char *BACKEND_URL = "https://trackthelife.hurated.com";
const char *UPLOAD_ENDPOINT = "/api/media";
```

**Full upload URL**: `https://trackthelife.hurated.com/api/media`

### Local Testing URL

For development on local network:
```cpp
const char *BACKEND_URL = "http://192.168.1.100:4000";
```

---

## Environment Variables

### .env (Server)
```bash
PORT=4000                                    # Internal container port
EXTERNAL_PORT=6000                           # Host port (nginx proxies here)
PUBLIC_URL=https://trackthelife.hurated.com  # Public-facing URL

APERTUREDB_URL=http://localhost:5555
APERTUREDB_API_KEY=your_key_here

TELNYX_API_KEY=your_key_here

MEMMACHINE_URL=http://localhost:7860
MEMMACHINE_API_KEY=your_key_here

COMET_API_KEY=your_key_here
COMET_WORKSPACE=trackthelife
```

### wifi_config.h (ESP32)
```cpp
const char *WIFI_SSID = "Guest";
const char *WIFI_PASSWORD = "BrokenWires@@2019";
const char *BACKEND_URL = "https://trackthelife.hurated.com";
const char *USER_ID = "esp32-cam-01";
const unsigned long CAPTURE_INTERVAL_MS = 5000;
```

---

## Architecture

```
ESP32 Camera
    ↓ HTTPS (WiFiClientSecure)
trackthelife.hurated.com (nginx :443)
    ↓ HTTP proxy
localhost:6000 (Docker host)
    ↓
trackthelife-backend container (:4000)
    ↓
ApertureDB + MemMachine + Telnyx + Comet
```

---

## Troubleshooting

### Container won't start
```bash
docker compose logs backend
```

### Port already in use
Check `.env` and change `EXTERNAL_PORT` to another free port ending in `000`.

### ESP32 can't connect
- Verify nginx is proxying correctly
- Check firewall allows port 443
- Test: `curl https://trackthelife.hurated.com/api/health`
- ESP32 serial output shows connection errors

### Certificate issues
ESP32 uses `.setInsecure()` to skip certificate validation. If you want proper validation, you'll need to embed the SSL certificate in the sketch.

---

## Monitoring

### Check service status
```bash
docker compose ps
```

### View logs
```bash
docker compose logs -f backend
```

### Check resource usage
```bash
docker stats trackthelife-backend
```
