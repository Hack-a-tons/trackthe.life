# IP Geolocation Feature

## Overview

trackthe.life automatically determines location from multiple sources:

1. **GPS data** (from phone app) - most accurate
2. **IP geolocation** (from ESP32/client IP) - fallback when GPS unavailable

Both location sources are stored for analytics and cross-validation.

---

## How It Works

### When Media is Uploaded

```
ESP32/Phone → Backend
    ↓
Extract Client IP
    ↓
Query ip-api.com
    ↓
Store GPS + IP Location
    ↓
ApertureDB + MemMachine
```

### IP Geolocation Service

**Provider**: http://ip-api.com  
**Free tier**: 45 requests/minute  
**No API key required**

**Example Request**:
```bash
curl http://ip-api.com/json/24.48.0.1
```

**Example Response**:
```json
{
  "query": "24.48.0.1",
  "status": "success",
  "country": "Canada",
  "countryCode": "CA",
  "region": "QC",
  "regionName": "Quebec",
  "city": "Montreal",
  "zip": "H1K",
  "lat": 45.6085,
  "lon": -73.5493,
  "timezone": "America/Toronto",
  "isp": "Le Groupe Videotron Ltee",
  "org": "Videotron Ltee",
  "as": "AS5769 Videotron Ltee"
}
```

---

## Location Priority

### 1. GPS Location (Preferred)
- Provided by phone app
- Accuracy: ~5-50 meters
- Format: `"37.7749,-122.4194"`
- Always used when available

### 2. IP Geolocation (Fallback)
- Extracted from client IP address
- Accuracy: City-level (~10-50 km)
- Automatically used when GPS unavailable
- Skipped for local/private IPs

### 3. Both Stored
Even when GPS is available, IP location is also stored for:
- Cross-validation
- ISP analytics
- Network pattern detection
- Fraud detection

---

## API Response

### With GPS Only
```json
{
  "status": "ok",
  "media_id": "abc123",
  "location": "37.7749,-122.4194",
  "ipLocation": null
}
```

### With IP Geolocation Only
```json
{
  "status": "ok",
  "media_id": "abc123",
  "location": "45.6085,-73.5493",
  "ipLocation": {
    "city": "Montreal",
    "region": "Quebec",
    "country": "Canada"
  }
}
```

### With Both
```json
{
  "status": "ok",
  "media_id": "abc123",
  "location": "37.7749,-122.4194",
  "ipLocation": {
    "city": "Montreal",
    "region": "Quebec",
    "country": "Canada"
  }
}
```

---

## Stored Metadata

### In ApertureDB
```javascript
{
  user_id: "demo-user",
  timestamp: "2025-11-04T13:00:00Z",
  location: "37.7749,-122.4194",  // GPS if available
  ip: "24.48.0.1",
  ipLocation: {
    ip: "24.48.0.1",
    country: "Canada",
    countryCode: "CA",
    region: "QC",
    regionName: "Quebec",
    city: "Montreal",
    zip: "H1K",
    lat: 45.6085,
    lon: -73.5493,
    timezone: "America/Toronto",
    isp: "Le Groupe Videotron Ltee",
    org: "Videotron Ltee",
    as: "AS5769 Videotron Ltee"
  }
}
```

### In MemMachine
```
User demo-user captured media at 2025-11-04T13:00:00Z 
at GPS location 37.7749,-122.4194 
from Montreal, Quebec, Canada
```

---

## Use Cases

### 1. GPS Unavailable
- Indoor locations (weak GPS signal)
- ESP32 without phone app
- Privacy mode (GPS disabled)
- **Solution**: Use IP geolocation as fallback

### 2. Location Validation
- Compare GPS vs IP location
- Detect GPS spoofing
- Verify user is in expected region

### 3. Network Analytics
- Track ISP usage patterns
- Identify mobile vs home network
- Detect VPN/proxy usage

### 4. Timezone Detection
- Automatic timezone from IP location
- Correct timestamp display
- Schedule local notifications

### 5. Content Localization
- Show nearby events
- Local language preferences
- Regional content filtering

---

## Privacy Considerations

### What is Stored
- Client IP address
- City-level location (not exact address)
- ISP information
- Timezone

### What is NOT Stored
- Exact street address
- Building/apartment number
- Personal identifiable info from IP

### User Control
- GPS can be disabled (falls back to IP)
- IP location is approximate (city-level)
- Data stored for analytics only

---

## Rate Limits

### ip-api.com Free Tier
- **45 requests/minute**
- **Unlimited daily requests**
- **No API key required**

### Handling Rate Limits
```javascript
// Automatic retry with exponential backoff
// Caching of recent IP lookups
// Graceful degradation (returns null if fails)
```

### Upgrade Options
If you exceed free tier:
- **Pro tier**: $13/month for 1000 req/min
- **Self-hosted**: Use MaxMind GeoIP2 database

---

## Implementation

### Backend Code
```javascript
// server/services/geoipClient.js
const geoip = require('./services/geoipClient');

// In route handler
const clientIp = req.headers['x-forwarded-for']?.split(',')[0] || 
                 req.connection.remoteAddress;
const ipLocation = await geoip.lookup(clientIp);
```

### ESP32 Behavior
- ESP32 uploads media with its external IP
- Backend extracts IP from request
- Automatic geolocation lookup
- No ESP32 code changes needed

### Phone App Behavior
- Sends GPS if available: `location=37.7749,-122.4194`
- Backend still logs IP location for analytics
- Both locations stored in metadata

---

## Testing

### Test with curl
```bash
# Without GPS (uses IP geolocation)
curl -X POST http://localhost:4000/api/media \
  -F "file=@test.jpg" \
  -F "user_id=test" \
  -F "timestamp=$(date -Iseconds)"

# With GPS (stores both)
curl -X POST http://localhost:4000/api/media \
  -F "file=@test.jpg" \
  -F "user_id=test" \
  -F "timestamp=$(date -Iseconds)" \
  -F "location=37.7749,-122.4194"
```

### Test IP Lookup Directly
```bash
curl http://ip-api.com/json/24.48.0.1
```

---

## Monitoring

### Comet/Opik Logs
```javascript
{
  operation: "media_upload",
  has_gps: true,
  has_ip_location: true,
  duration: 1234
}
```

### Check Location Data
- View in ApertureDB queries
- Check MemMachine memories
- Monitor Comet traces

---

## Future Enhancements

1. **Caching**: Cache IP lookups for 24h
2. **Batch lookups**: Group multiple IPs
3. **Offline database**: Use MaxMind for faster lookups
4. **Location history**: Track user movement patterns
5. **Geofencing**: Trigger actions based on location
