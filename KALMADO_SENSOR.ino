#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// ===== WIFI CONFIG =====
#define WIFI_SSID "HUAWEI-2.4G-Skb3"
#define WIFI_PASSWORD "aGsjMD6F"

// ===== FIREBASE REST URL =====
const char* FIREBASE_URL = "https://kalmado-appdev-default-rtdb.asia-southeast1.firebasedatabase.app/classroom.json";

// ===== SENSOR PINS =====
#define DHTPIN 4
#define DHTTYPE DHT11
#define NOISE_PIN 34
#define LDR_PIN 35
#define GAS_PIN 32

DHT dht(DHTPIN, DHTTYPE);

// ===== HELPER FUNCTIONS =====

// 🌡 TEMPERATURE
String getTemperatureStatus(float t) {
  if (t < 22) return "CRITICAL";
  if (t <= 24) return "MODERATE";
  if (t <= 28) return "COMFORTABLE";
  if (t <= 31) return "MODERATE";
  return "CRITICAL";
}

// 💧 HUMIDITY
String getHumidityStatus(float h) {
  if (h < 40) return "CRITICAL";
  if (h <= 59) return "MODERATE";
  if (h <= 70) return "COMFORTABLE";
  if (h <= 85) return "MODERATE";
  return "CRITICAL";
}

// 💡 LIGHT (FIXED + INVERTED LOGIC)
String getLightStatus(int l) {
  if (l < 300) return "CRITICAL";        // too dark
  if (l < 800) return "MODERATE";        // slightly dim
  if (l <= 2000) return "COMFORTABLE";   // ideal
  if (l <= 3000) return "MODERATE";      // slightly bright
  return "CRITICAL";                     // too bright
}

// 🌫 GAS
String getGasStatus(int g) {
  if (g > 280) return "CRITICAL";
  if (g > 220) return "MODERATE";
  return "COMFORTABLE";
}

// 🔊 NOISE (RAW for now)
String getNoiseStatus(int n) {
  if (n > 2000) return "CRITICAL";   // adjusted for raw analog
  if (n > 1000) return "MODERATE";
  return "COMFORTABLE";
}

// 🎯 OVERALL STATUS
String getOverallStatus(float t, float h, int l, int g, int n) {

  String ts = getTemperatureStatus(t);
  String hs = getHumidityStatus(h);
  String ls = getLightStatus(l);
  String gs = getGasStatus(g);
  String ns = getNoiseStatus(n);

  if (ts == "CRITICAL" || hs == "CRITICAL" || ls == "CRITICAL" || gs == "CRITICAL" || ns == "CRITICAL") {
    return "CRITICAL";
  }

  if (ts == "MODERATE" || hs == "MODERATE" || ls == "MODERATE" || gs == "MODERATE" || ns == "MODERATE") {
    return "MODERATE";
  }

  return "COMFORTABLE";
}

// ===== WIFI =====
void connectToWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected to WiFi");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(NOISE_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(GAS_PIN, INPUT);

  connectToWiFi();
}

// ===== LOOP =====
void loop() {

  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("DHT read error");
    delay(3000);
    return;
  }

  int noiseValue = analogRead(NOISE_PIN);

  // 🔥 FIXED LIGHT VALUE
  int rawLight = analogRead(LDR_PIN);
  int lightValue = 4095 - rawLight;

  int gasValue = analogRead(GAS_PIN);

  // ===== STATUS =====
  String tempStatus = getTemperatureStatus(temperature);
  String humidityStatus = getHumidityStatus(humidity);
  String lightStatus = getLightStatus(lightValue);
  String gasStatus = getGasStatus(gasValue);
  String noiseStatus = getNoiseStatus(noiseValue);
  String overallStatus = getOverallStatus(temperature, humidity, lightValue, gasValue, noiseValue);

  // ===== JSON =====
  String json = "{";
  json += "\"temperature\":" + String(temperature, 1) + ",";
  json += "\"humidity\":" + String(humidity, 1) + ",";
  json += "\"noise\":" + String(noiseValue) + ",";
  json += "\"light\":" + String(lightValue) + ",";
  json += "\"gas\":" + String(gasValue) + ",";
  json += "\"status\":\"" + overallStatus + "\",";
  json += "\"timestamp\":" + String(millis());
  json += "}";

  // ===== SERIAL =====
  Serial.println("\n===== KALMADO =====");

  Serial.print("Temp: "); Serial.print(temperature); Serial.print(" | "); Serial.println(tempStatus);
  Serial.print("Humidity: "); Serial.print(humidity); Serial.print(" | "); Serial.println(humidityStatus);
  Serial.print("Light: "); Serial.print(lightValue); Serial.print(" | "); Serial.println(lightStatus);
  Serial.print("Noise: "); Serial.print(noiseValue); Serial.print(" | "); Serial.println(noiseStatus);
  Serial.print("Gas: "); Serial.print(gasValue); Serial.print(" | "); Serial.println(gasStatus);

  Serial.print("Overall: "); Serial.println(overallStatus);

  Serial.println("JSON:");
  Serial.println(json);

  // ===== SEND TO FIREBASE =====
  HTTPClient http;
  http.begin(FIREBASE_URL);
  http.addHeader("Content-Type", "application/json");

  int code = http.PUT(json);

  Serial.print("HTTP Code: ");
  Serial.println(code);

  if (code == 200) {
    Serial.println("Sent to Firebase ✔");
  } else {
    Serial.println("Error sending ❌");
  }

  http.end();

  Serial.println("====================");

  delay(3000);
}




