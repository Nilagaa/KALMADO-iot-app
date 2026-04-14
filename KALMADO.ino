#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// ===== WIFI =====
#define WIFI_SSID "Rukia"
#define WIFI_PASSWORD "alexandra"

// ===== FIREBASE =====
const char* FIREBASE_URL = "https://kalmado-appdev-default-rtdb.asia-southeast1.firebasedatabase.app/classroom.json";

// ===== SENSOR PINS =====
#define DHTPIN 4
#define DHTTYPE DHT11
#define NOISE_PIN 36
#define LDR_PIN 35
#define GAS_PIN 32

DHT dht(DHTPIN, DHTTYPE);

// ===== NOISE CALIBRATION =====
int noiseBaseline = 0;
const int NOISE_HEADROOM = 10;
const int NOISE_ACTIVE_RANGE = 600;

// ===== STATUS FUNCTIONS =====

// Temperature
String getTemperatureStatus(float t) {
  if (t < 22) return "CRITICAL";
  if (t < 24) return "MODERATE";
  if (t <= 28) return "COMFORTABLE";
  if (t <= 31) return "MODERATE";
  return "CRITICAL";
}

// Humidity
String getHumidityStatus(float h) {
  if (h < 40) return "CRITICAL";
  if (h <= 59) return "MODERATE";
  if (h <= 70) return "COMFORTABLE";
  if (h <= 85) return "MODERATE";
  return "CRITICAL";
}

// Light (0–100)
String getLightStatus(int l) {
  if (l <= 20) return "CRITICAL";
  if (l <= 40) return "MODERATE";
  if (l <= 80) return "COMFORTABLE";
  return "CRITICAL";
}

// Gas (0–100)
String getGasStatus(int g) {
  if (g <= 20) return "COMFORTABLE";
  if (g <= 50) return "MODERATE";
  return "CRITICAL";
}

// Noise (0–100)
String getNoiseStatus(int n) {
  if (n <= 20) return "COMFORTABLE";
  if (n <= 50) return "MODERATE";
  return "CRITICAL";
}

// ===== STATUS TO SCORE =====
int statusToScore(String s) {
  if (s == "COMFORTABLE") return 3;
  if (s == "MODERATE") return 2;
  return 1;
}

// ===== OVERALL ROOM STATUS BY AVERAGE =====
String computeRoomStatus(
  String ts,
  String hs,
  String ls,
  String gs,
  String ns
) {
  int total =
    statusToScore(ts) +
    statusToScore(hs) +
    statusToScore(ls) +
    statusToScore(gs) +
    statusToScore(ns);

  float avg = total / 5.0;

  if (avg >= 2.5) return "COMFORTABLE";
  if (avg >= 1.5) return "MODERATE";
  return "CRITICAL";
}

// ===== NOISE FUNCTIONS =====
int readNoiseAmplitude() {
  int maxVal = 0;
  int minVal = 4095;

  unsigned long start = millis();

  while (millis() - start < 50) {
    int val = analogRead(NOISE_PIN);
    if (val > maxVal) maxVal = val;
    if (val < minVal) minVal = val;
  }

  return maxVal - minVal;
}

void calibrateNoise() {
  long total = 0;
  for (int i = 0; i < 40; i++) {
    total += readNoiseAmplitude();
    delay(50);
  }
  noiseBaseline = total / 40;
}

int normalizeNoise(int amp) {
  int adjusted = amp - noiseBaseline - NOISE_HEADROOM;
  if (adjusted < 0) adjusted = 0;

  int percent = map(adjusted, 0, NOISE_ACTIVE_RANGE, 0, 100);

  if (percent < 0) percent = 0;
  if (percent > 100) percent = 100;

  return percent;
}

// ===== LIGHT NORMALIZATION =====
int normalizeLight(int rawLight) {
  int inverted = 4095 - rawLight;
  int percent = 0;

  if (inverted <= 900) {
    percent = 1;
  }
  else if (inverted <= 2000) {
    percent = map(inverted, 901, 2000, 1, 20);
  }
  else if (inverted <= 3200) {
    percent = map(inverted, 2001, 3200, 21, 40);
  }
  else if (inverted <= 3800) {
    percent = map(inverted, 3201, 3800, 41, 80);
  }
  else {
    percent = map(inverted, 3801, 4095, 81, 100);
  }

  if (percent < 1) percent = 1;
  if (percent > 100) percent = 100;

  return percent;
}

// ===== GAS NORMALIZATION =====
int normalizeGas(int rawGas) {
  int percent = 0;

  if (rawGas <= 130) {
    percent = map(rawGas, 90, 130, 0, 20);
  }
  else if (rawGas <= 200) {
    percent = map(rawGas, 131, 200, 21, 50);
  }
  else if (rawGas <= 600) {
    percent = map(rawGas, 201, 600, 51, 100);
  }
  else {
    percent = 100;
  }

  if (percent < 0) percent = 0;
  if (percent > 100) percent = 100;

  return percent;
}

// ===== WIFI =====
void connectToWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected ✔");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  dht.begin();

  analogReadResolution(12);
  analogSetPinAttenuation(NOISE_PIN, ADC_11db);
  analogSetPinAttenuation(LDR_PIN, ADC_11db);
  analogSetPinAttenuation(GAS_PIN, ADC_11db);

  connectToWiFi();
  calibrateNoise();
}

// ===== LOOP =====
void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h)) {
    Serial.println("DHT ERROR");
    delay(2000);
    return;
  }

  // ===== SENSOR READINGS =====
  int rawLight = analogRead(LDR_PIN);
  int light = normalizeLight(rawLight);

  int rawGas = analogRead(GAS_PIN);
  int gas = normalizeGas(rawGas);

  int amp = readNoiseAmplitude();
  int noise = normalizeNoise(amp);

  // ===== SENSOR STATUS =====
  String tempStatus = getTemperatureStatus(t);
  String humStatus = getHumidityStatus(h);
  String lightStatus = getLightStatus(light);
  String gasStatus = getGasStatus(gas);
  String noiseStatus = getNoiseStatus(noise);

  // ===== ROOM STATUS =====
  String overall = computeRoomStatus(
    tempStatus,
    humStatus,
    lightStatus,
    gasStatus,
    noiseStatus
  );

  // ===== JSON =====
  String json = "{";
  json += "\"temperature\":" + String(t, 1) + ",";
  json += "\"humidity\":" + String(h, 1) + ",";
  json += "\"light\":" + String(light) + ",";
  json += "\"gas\":" + String(gas) + ",";
  json += "\"noise\":" + String(noise) + ",";
  json += "\"temperatureStatus\":\"" + tempStatus + "\",";
  json += "\"humidityStatus\":\"" + humStatus + "\",";
  json += "\"lightStatus\":\"" + lightStatus + "\",";
  json += "\"gasStatus\":\"" + gasStatus + "\",";
  json += "\"noiseStatus\":\"" + noiseStatus + "\",";
  json += "\"status\":\"" + overall + "\",";
  json += "\"timestamp\":" + String(millis());
  json += "}";

  // ===== SERIAL =====
  Serial.println("\n===== KALMADO =====");
  Serial.print("Temperature: ");
  Serial.print(t);
  Serial.print(" | ");
  Serial.println(tempStatus);

  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.print(" | ");
  Serial.println(humStatus);

  Serial.print("Light: ");
  Serial.print(light);
  Serial.print(" | ");
  Serial.println(lightStatus);

  Serial.print("Gas: ");
  Serial.print(gas);
  Serial.print(" | ");
  Serial.println(gasStatus);

  Serial.print("Noise: ");
  Serial.print(noise);
  Serial.print(" | ");
  Serial.println(noiseStatus);

  Serial.print("Room Status: ");
  Serial.println(overall);

  Serial.println("JSON:");
  Serial.println(json);

  // ===== SEND TO FIREBASE =====
  HTTPClient http;
  http.begin(FIREBASE_URL);
  http.addHeader("Content-Type", "application/json");

  int code = http.PUT(json);

  Serial.print("HTTP: ");
  Serial.println(code);

  if (code == 200) {
    Serial.println("Sent to Firebase ✔");
  } else {
    Serial.println("Error sending ❌");
  }

  http.end();

  delay(1000);
}