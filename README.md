# AQUA-SENSE: AI-Powered IoT System for Public Water Quality Monitoring & Predictive Alerts

AquaSense is an IoT and AI-based water quality monitoring system designed to support **real-time monitoring, cloud-based data visualization, intelligent alerts, predictive analysis, and user feedback** for public and private water systems.

The system combines **ESP32-based sensor acquisition, LoRa wireless communication, Firebase Realtime Database, a Flutter mobile application, and a CNN-LSTM-based prediction system with Explainable AI (XAI)**.

---

## 📌 Project Overview

Traditional water quality monitoring often depends on periodic sample collection and laboratory analysis. This can make continuous monitoring difficult and may delay the detection of abnormal water conditions.

AquaSense proposes an integrated monitoring system in which water quality parameters are collected using sensors connected to an ESP32-based sensor node. The readings are transmitted using LoRa to a receiver/base station and stored in Firebase. The mobile application retrieves the stored data and provides monitoring, prediction, historical data, alerts, and feedback features.

The project combines:

* Internet of Things (IoT)
* LoRa wireless communication
* Cloud database
* Mobile application development
* Machine Learning
* Explainable AI

---

## 🎯 Objectives

The main objectives of AquaSense are:

* To continuously monitor important water quality parameters.
* To collect sensor readings using an ESP32-based sensor node.
* To transmit sensor data wirelessly using LoRa communication.
* To store sensor readings in Firebase Realtime Database.
* To provide a mobile interface for viewing water quality information.
* To provide historical sensor data for analysis.
* To classify water quality using an AI-based prediction model.
* To provide Explainable AI-based recommendations.
* To provide alerts for abnormal or unsafe conditions.
* To provide a feedback mechanism for users.

---

## ⚙️ System Architecture

The implemented system follows the general data flow:

```text
Water Quality Sensors
        ↓
ESP32 Sensor Node
        ↓
LoRa Transmission
        ↓
ESP32 Receiver / Base Station
        ↓
Wi-Fi
        ↓
Firebase Realtime Database
        ↓
Flutter Mobile Application
        ↓
Prediction & Explainable AI
        ↓
Alerts / Recommendations / Historical Data
```

---

## 🔬 Sensor Data Acquisition

The ESP32 sensor node interfaces with water quality sensors and processes their readings before transmission.

The current sensor-node implementation reads:

* Temperature
* pH
* Turbidity
* TDS
* ORP

The sensor node converts the analog readings into corresponding values and sends the readings through LoRa.

### Current Data Flow

The sensor node transmits the following values:

```text
Temperature, pH, Turbidity, TDS, ORP
```

The current receiver implementation processes and stores:

```text
Temperature
pH
Turbidity
TDS
```

ORP is currently read and transmitted by the sensor node but is not processed or stored by the current receiver implementation.

---

## 📡 LoRa Communication

LoRa is used to provide wireless communication between the sensor node and the receiver/base station.

### Sender

The ESP32 sensor node:

1. Reads the connected sensors.
2. Processes the sensor values.
3. Creates a data packet.
4. Transmits the packet using a LoRa module.

### Receiver

The receiver ESP32:

1. Receives the LoRa packet.
2. Parses the sensor values.
3. Connects to Wi-Fi.
4. Updates the Firebase Realtime Database.

The current implementation uses **433 MHz LoRa communication**.

---

## ☁️ Firebase Cloud Database

Firebase Realtime Database is used to store the sensor readings received by the ESP32 receiver.

The current receiver stores:

```text
temperature
ph
turbidity
tds
```

The Firebase database also acts as the cloud data source for the mobile application.

---

## 📱 Mobile Application

The AquaSense mobile application is developed using **Flutter and Dart**.

The application contains separate screens for different system functions.

### Main Features

* User registration and login
* Home dashboard
* Live sensor readings
* Water quality prediction
* Historical data
* Alerts
* User feedback
* Navigation drawer
* Admin-related functionality

The application retrieves sensor data from Firebase and communicates with the prediction backend when prediction functionality is used.

---

## 🤖 AI / Machine Learning

AquaSense uses a **CNN-LSTM model** for water quality classification.

The model development workflow includes:

```text
Dataset
   ↓
Data Loading
   ↓
Data Preprocessing
   ↓
Train-Test Split
   ↓
CNN-LSTM Model Training
   ↓
Model Evaluation
   ↓
Model Deployment
```

The current prediction backend uses four input parameters:

* Temperature
* pH
* Turbidity
* TDS

The trained model is stored in:

```text
source-code/ai-ml/cnnlstm_model.h5
```

The corresponding feature scaler is stored in:

```text
source-code/ai-ml/aqua_sense_scaler.pkl
```

---

## 🔍 Explainable AI

AquaSense incorporates **Explainable AI (XAI)** using SHAP-based analysis.

The purpose of XAI is to provide information about how the input parameters contribute to the prediction rather than presenting only the final prediction result.

The backend can generate feature-level explanations and recommendations based on the sensor values and prediction output.

The XAI implementation is located within the backend prediction system.

---

## 🧠 Backend

The backend is implemented using **Python and Flask**.

It provides API endpoints for:

* Health checking
* Model information
* Water quality prediction
* Explainable AI analysis

Main backend files:

```text
source-code/backend/
├── app.py
├── requirements.txt
├── test_backend_logic.py
├── README.md
├── README_XAI.md
└── code.ipynb
```

The backend loads the trained CNN-LSTM model and scaler and processes prediction requests from the application.

---

## 🛠️ Technology Stack

### Hardware

* ESP32
* LoRa SX1278
* Temperature sensor
* pH sensor
* Turbidity sensor
* TDS sensor
* ORP sensor

### Embedded System

* Arduino IDE
* Embedded C / Arduino C++
* LoRa communication

### Mobile Application

* Flutter
* Dart

### Cloud

* Firebase Realtime Database
* Firebase Authentication

### Backend

* Python
* Flask
* Flask-CORS

### AI / Machine Learning

* TensorFlow
* CNN-LSTM
* NumPy
* Pandas
* Scikit-learn
* Joblib
* SHAP

---

## 📂 Project Structure

```text
Aqua-Sense - Git Hub purpose/
│
├── source-code/
│   │
│   ├── mobile-app/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   │
│   ├── backend/
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   ├── test_backend_logic.py
│   │   ├── README.md
│   │   ├── README_XAI.md
│   │   └── code.ipynb
│   │
│   ├── ai-ml/
│   │   ├── cnnlstm_model.h5
│   │   └── aqua_sense_scaler.pkl
│   │
│   └── esp32/
│       ├── esp32_node.ino
│       └── esp32_receiver.ino
│
├── documentation/
│   ├── Feasibility Study
│   ├── Abstract
│   ├── Hardware & Software Requirements
│   └── Literature Review
│
├── diagrams/
│
├── screenshots/
│
└── hardware/
    ├── sender-side-prototype
    └── receiver-side-prototype
```

---

## 📚 Documentation

The repository includes project documentation covering:

* Feasibility Study
* Project Abstract
* Hardware and Software Requirements
* Literature Review
* System Architecture
* Data Flow and Workflow Diagrams
* Circuit Diagram
* AI/ML Pipeline

---

## 🖼️ Screenshots

The `screenshots` directory contains selected screens from the AquaSense mobile application, including:

* Login
* Home
* Navigation
* Prediction
* History
* Alerts
* Feedback
* Admin interface
* Logout

---

## 🔧 Hardware Prototype

The `hardware` directory contains photographs of the developed prototypes:

* Sensor-side prototype
* Receiver-side prototype

These demonstrate the physical implementation of the ESP32 and LoRa-based communication system.

---

## 🔐 Security Note

Sensitive credentials are intentionally excluded from this repository.

The GitHub-safe ESP32 receiver code uses placeholders such as:

```cpp
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL"
#define USER_EMAIL "YOUR_FIREBASE_USER_EMAIL"
#define USER_PASSWORD "YOUR_FIREBASE_USER_PASSWORD"
```

Actual credentials should be supplied only in the local development environment and should **not be committed to a public repository**.

---

## 🚧 Current Implementation

The current repository represents the implemented project components, including:

* ESP32 sensor acquisition
* LoRa-based sensor communication
* ESP32 receiver/base station
* Firebase Realtime Database integration
* Flutter mobile application
* Flask prediction backend
* CNN-LSTM model
* SHAP-based Explainable AI
* Historical data
* Alerts
* User feedback

Some components described in the original project proposal are planned extensions rather than part of the current implementation.

---

## 🔮 Future Enhancements

Potential future improvements include:

* Integration of additional water quality parameters such as dissolved oxygen and electrical conductivity.
* Improved sensor calibration and validation using laboratory measurements.
* Offline data storage and synchronization at the base station.
* Improved LoRa reliability and error handling.
* Model retraining using larger real-world datasets.
* Field deployment and long-term monitoring.
* More extensive real-world model validation.
* Improved scalability for multiple sensor nodes.
* Further optimization of power consumption for remote deployments.

---

## 👥 Project Team

**AquaSense** was developed as a final-year Bachelor of Technology project in Computer Science and Engineering.

**Institution:**
Sree Narayana Gurukulam College of Engineering, Kadayiruppu

**University:**
APJ Abdul Kalam Technological University (KTU)

### Team Members

* Arya Babu
* Ahsana Fathima A
* Aneetta K J
* Arathy Jerome

---

## 📌 Project Status

**Academic Project / Final-Year Project**

AquaSense demonstrates the integration of IoT, wireless communication, cloud services, mobile application development, machine learning, and Explainable AI into a unified water quality monitoring prototype.

---

## 📄 License

This project was developed for academic and educational purposes.
