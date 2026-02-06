# KALMADO-iot-app
KALMADO is a mobile application designed to help Special Needs Education (SNED) teachers monitor and manage classroom sensory conditions in real time. The application collects environmental data from IoT sensors installed in the classroom such as noise level, temperature, lighting, and odor and displays the information in an easy to understand dashboard.

By providing real-time alerts, historical analytics, and a sensory comfort status indicator, KALMADO supports teachers in making timely, data-driven decisions to improve students’ focus, emotional regulation, and overall learning experience.

## Technologies Used
- FRAMEWORK: Flutter (Cross-platform)
- LANGUAGE: Dart
- HARDWARE: IoT (ESP32 Microcontroller + Environmental Sensors)
- CLOUD PLATFORM: Firebase (Real-time Database, Notifications, Data Processing)

## Core Features
- REAL-TIME MONITORING: Live display of noise, temperature, light, and odor levels.
- COMFORT INDICATOR: Overall status: Comfortable, Moderate, or Critical.
- THRESHOLD ALERTS: Automatic notifications when levels exceed comfort limits.
- TREND ANALYTICS: Daily and weekly historical sensor data trends.
- DATA VISUALIZATION: Integrated line charts and bar graphs for interpretation.
- TEACHER DASHBOARD: Centralized view of all real-time data and alerts.
- CLOUD STORAGE: Secure and scalable environmental data logging.

## Installation Instructions

1. CLONE REPOSITORY:
```$ git clone https://github.com/Nilagaa/KALMADO.git```
2. NAVIGATE TO DIRECTORY:
```$ cd KALMADO```
3. INSTALL DEPENDENCIES:
```$ flutter pub get```
4. RUN APPLICATION:
```$ flutter run```

## System Setup

[ IOT DEVICE SETUP ]
1. Connect sensors (Sound, DHT11, LDR, MQ-135) to the ESP32 microcontroller.
2. Open the source code in Arduino IDE and install Firebase/WiFi libraries.
3. Update the WiFi SSID, Password, and Firebase API credentials.
4. Flash the firmware to the ESP32.

[ CLOUD SERVICES SETUP ]
1. Create a project in the Firebase Console.
2. Enable "Realtime Database" and "Cloud Messaging".
3. Register your app and download 'google-services.json' or 'GoogleService-Info.plist'.
4. Place the config files in the respective android/app/ or ios/Runner/ folders.

DEVELOPED BY: Group 3 - IT32S2
