/**********************************************************************
  Filename    : trackthelife_camera.ino
  Description : ESP32 camera that captures frames and uploads to backend
  Project     : trackthe.life
  Hardware    : Freenove ESP32-WROVER with camera module
**********************************************************************/

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include "wifi_config.h"
#include "camera_pins.h"

#define CAMERA_MODEL_WROVER_KIT

camera_config_t config;
unsigned long lastCaptureTime = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== trackthe.life Camera Starting ===");
  
  // Initialize camera
  initCamera();
  
  // Connect to WiFi
  connectWiFi();
  
  Serial.println("=== Setup Complete ===");
  Serial.printf("Capturing every %lu ms\n", CAPTURE_INTERVAL_MS);
}

void loop() {
  if (millis() - lastCaptureTime >= CAPTURE_INTERVAL_MS) {
    captureAndUpload();
    lastCaptureTime = millis();
  }
  delay(100);
}

void initCamera() {
  Serial.println("Initializing camera...");
  
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 10000000;
  config.frame_size = FRAMESIZE_SVGA;  // 800x600
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;  // 0-63, lower is higher quality
  config.fb_count = 1;
  
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed: 0x%x\n", err);
    while(1);
  }
  
  sensor_t *s = esp_camera_sensor_get();
  s->set_vflip(s, 0);
  s->set_hmirror(s, 0);
  s->set_brightness(s, 1);
  s->set_saturation(s, -1);
  
  Serial.println("Camera initialized");
}

void connectWiFi() {
  Serial.printf("Connecting to WiFi: %s\n", WIFI_SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  WiFi.setSleep(false);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi connection failed!");
  }
}

void captureAndUpload() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, reconnecting...");
    connectWiFi();
    return;
  }
  
  Serial.println("Capturing frame...");
  camera_fb_t *fb = esp_camera_fb_get();
  
  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }
  
  Serial.printf("Frame captured: %d bytes\n", fb->len);
  
  // Upload to backend
  HTTPClient http;
  String url = String("http://") + BACKEND_HOST + ":" + BACKEND_PORT + UPLOAD_ENDPOINT;
  
  http.begin(url);
  
  // Build multipart form data
  String boundary = "----trackthelife" + String(millis());
  String contentType = "multipart/form-data; boundary=" + boundary;
  http.addHeader("Content-Type", contentType);
  
  String body = "--" + boundary + "\r\n";
  body += "Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n";
  body += "Content-Type: image/jpeg\r\n\r\n";
  
  String footer = "\r\n--" + boundary + "\r\n";
  footer += "Content-Disposition: form-data; name=\"user_id\"\r\n\r\n";
  footer += USER_ID;
  footer += "\r\n--" + boundary + "\r\n";
  footer += "Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n";
  footer += String(millis());
  footer += "\r\n--" + boundary + "--\r\n";
  
  int totalLen = body.length() + fb->len + footer.length();
  
  uint8_t *payload = (uint8_t*)malloc(totalLen);
  if (!payload) {
    Serial.println("Failed to allocate memory");
    esp_camera_fb_return(fb);
    return;
  }
  
  memcpy(payload, body.c_str(), body.length());
  memcpy(payload + body.length(), fb->buf, fb->len);
  memcpy(payload + body.length() + fb->len, footer.c_str(), footer.length());
  
  int httpCode = http.POST(payload, totalLen);
  
  free(payload);
  esp_camera_fb_return(fb);
  
  if (httpCode > 0) {
    Serial.printf("Upload response: %d\n", httpCode);
    if (httpCode == 200) {
      String response = http.getString();
      Serial.println("Response: " + response);
    }
  } else {
    Serial.printf("Upload failed: %s\n", http.errorToString(httpCode).c_str());
  }
  
  http.end();
}
