#include <SPI.h>
#include <LoRa.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// LoRa SX1278 Pins (SPI)
#define SS    5
#define RST   14
#define DIO0  2

// Digital Sensor
#define TEMP_PIN 4 

// Analog Sensors 
#define PH_PIN        34
#define TURBIDITY_PIN 35
#define TDS_PIN       32
#define ORP_PIN       33

// --- Objects ---
OneWire oneWire(TEMP_PIN);
DallasTemperature sensors(&oneWire);

void setup() {
  Serial.begin(115200);
  while (!Serial);
  sensors.begin();
  LoRa.setPins(SS, RST, DIO0);
  if (!LoRa.begin(433E6)) { // 433MHz
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  
  Serial.println("Aquasense Sensor Node Initialized.");
}

void loop() {
  // 1. Read Temperature
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);

  // 2. Read Analog Sensors (Averaging for stability)
  float phVolts = readAnalog(PH_PIN);
  float turbVolts = readAnalog(TURBIDITY_PIN);
  float tdsVolts = readAnalog(TDS_PIN);
  float orpVolts = readAnalog(ORP_PIN);

  // 3. Simple Conversions
  float pHValue = 3.5 * phVolts; 
  float turbidityNTU = map(turbVolts * 100, 0, 330, 1000, 0); 
  float orpMV = (orpVolts - 1.5) * 1000;
  
  // TDS calculation with temperature compensation
  float compensationCoefficient = 1.0 + 0.02 * (temperature - 25.0);
  float compensationVolts = tdsVolts / compensationCoefficient;
  float tdsValue = (133.42 * pow(compensationVolts, 3) - 255.86 * pow(compensationVolts, 2) + 857.39 * compensationVolts) * 0.5;

  // 4. Send Data via LoRa
  String packet = String(temperature) + "," + String(pHValue) + "," + 
                  String(turbidityNTU) + "," + String(tdsValue) + "," + String(orpMV);

  Serial.print("Sending Packet: ");
  Serial.println(packet);

  LoRa.beginPacket();
  LoRa.print(packet);
  LoRa.endPacket();

  delay(5000);
}

float readAnalog(int pin) {
  int raw = 0;
  for(int i=0; i<10; i++) {
    raw += analogRead(pin);
    delay(10);
  }
  return (raw / 10.0) * (3.3 / 4095.0);
}