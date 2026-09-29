#include <Arduino.h>
#include <WiFi.h>
#include <SPI.h>
#include <LoRa.h>
#include <FirebaseESP32.h>

// Mobizt helpers
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

/* WiFi Credentials
 * Replace these values with your actual credentials
 * when running the project locally.
 */
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

/* Firebase Credentials
 * Replace these values with your actual Firebase
 * configuration when running the project locally.
 */
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL"
#define USER_EMAIL "YOUR_FIREBASE_USER_EMAIL"
#define USER_PASSWORD "YOUR_FIREBASE_USER_PASSWORD"

/* LoRa Pins */
#define SS   5
#define RST  14
#define DIO0 2

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

void setup() {
  Serial.begin(115200);

  // WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }

  Serial.println("\nWiFi connected");

  // LoRa
  LoRa.setPins(SS, RST, DIO0);

  if (!LoRa.begin(433E6)) {
    Serial.println("LoRa init failed");
    while (1);
  }

  Serial.println("LoRa Receiver Ready");

  // Firebase configuration
  Serial.printf(
      "Firebase Client v%s\n",
      FIREBASE_CLIENT_VERSION
  );

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  config.token_status_callback = tokenStatusCallback;

  Firebase.reconnectNetwork(true);

  fbdo.setBSSLBufferSize(4096, 1024);

  Firebase.begin(&config, &auth);
  Firebase.setDoubleDigits(5);
}

void loop() {

  if (!Firebase.ready()) {
    return;
  }

  int packetSize = LoRa.parsePacket();

  if (!packetSize) {
    return;
  }

  String incoming = "";

  while (LoRa.available()) {
    incoming += (char)LoRa.read();
  }

  Serial.println("\n--- LoRa Packet ---");
  Serial.println(incoming);

  // The receiver currently processes
  // Temperature, pH, Turbidity and TDS.
  float temp;
  float ph;
  float turb;
  float tds;

  if (sscanf(
        incoming.c_str(),
        "%f,%f,%f,%f",
        &temp,
        &ph,
        &turb,
        &tds
      ) != 4) {

    Serial.println(
        "CSV Parse Error (Expected 4 values)"
    );

    return;
  }

  Serial.printf(
      "Temp: %.2f | pH: %.2f | Turb: %.2f | TDS: %.2f\n",
      temp,
      ph,
      turb,
      tds
  );

  // Prepare Firebase data
  FirebaseJson json;

  json.set("temperature", temp);
  json.set("ph", ph);
  json.set("turbidity", turb);
  json.set("tds", tds);

  // Update Firebase Realtime Database
  if (Firebase.updateNode(
        fbdo,
        "/sensor_readings",
        json
      )) {

    Serial.println("Firebase update OK");

  } else {

    Serial.print("Firebase error: ");
    Serial.println(fbdo.errorReason());
  }
}