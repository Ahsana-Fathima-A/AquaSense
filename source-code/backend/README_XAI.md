# AquaSense Backend with Explainable AI

The AquaSense backend provides water quality prediction using a CNN-LSTM model together with Explainable AI (XAI) techniques. The backend accepts water quality parameters, predicts whether the water is classified as **CLEAN** or **POLLUTED**, and provides SHAP-based explanations and recommendations.

## 🚀 Features

### Core Prediction

* **CNN-LSTM Model**: Deep learning model for water quality classification.
* **Binary Classification**: Predicts `CLEAN` or `POLLUTED`.
* **Real-time API Processing**: Provides predictions through a Flask REST API.
* **Four Input Parameters**:

  * Temperature
  * pH
  * Turbidity
  * TDS

### Explainable AI (XAI)

* **SHAP Value Analysis**: Explains the contribution of individual input features.
* **Feature Importance**: Identifies the influence of temperature, pH, turbidity, and TDS on a prediction.
* **Feature Ranking**: Ranks features according to the absolute magnitude of their SHAP values.
* **Explanation Summary**: Provides a summary of the SHAP-based analysis.
* **Detailed Analysis Endpoint**: Provides additional prediction, feature, recommendation, and model information.

### Recommendation System

The backend generates recommendations based on the predicted water quality and the input parameters.

Recommendations may include:

* Parameter-specific observations
* Immediate actions for polluted classifications
* Water-quality monitoring suggestions
* Preventive maintenance suggestions
* Treatment-related suggestions based on parameter values

---

## 📊 API Endpoints

### 1. Health Check

```http
GET /health
```

Checks whether the backend is running and reports the loading status of the model, scaler, and SHAP explainer.

### 2. Model Information

```http
GET /model/info
```

Returns information about:

* Model name
* Model version
* Input features
* Output classes
* Test-dataset accuracy recorded by the backend
* Model loading status
* Scaler loading status
* SHAP explainer status
* XAI availability

The current backend reports:

```text
Accuracy: 100% (Test Dataset)
```

This value refers to the test dataset used during model development and should not be interpreted as guaranteed real-world prediction accuracy.

### 3. Prediction

```http
POST /predict
Content-Type: application/json
```

Example request:

```json
{
    "temperature": 25.0,
    "ph": 7.2,
    "turbidity": 1.5,
    "tds": 120.0
}
```

The endpoint performs the following operations:

1. Validates the input.
2. Prepares and scales the input features.
3. Generates a CNN-LSTM prediction.
4. Classifies the result as `CLEAN` or `POLLUTED`.
5. Generates SHAP-based feature importance.
6. Generates recommendations.
7. Returns an explanation summary.

The response contains information such as:

* Prediction class
* Prediction probability
* Water quality status
* Model version
* Input data
* SHAP feature importance
* Recommendations
* Explanation summary
* Timestamp

### 4. Detailed SHAP Analysis

```http
POST /explain
Content-Type: application/json
```

Example request:

```json
{
    "temperature": 30.5,
    "ph": 6.7,
    "turbidity": 8.2,
    "tds": 380.0
}
```

The `/explain` endpoint provides a more detailed analysis containing:

* Prediction result
* Input parameters
* Feature analysis
* Recommendations
* Most influential feature
* Feature ranking
* Model information
* SHAP explanation details

The model information returned by this endpoint identifies the model as **CNN-LSTM** and the explanation method as **SHAP DeepExplainer**.

---

## 🔬 Water Quality Parameters

The current prediction model uses four parameters.

### Temperature

Measured in degrees Celsius (°C).

Temperature is one of the four features supplied to the CNN-LSTM model and is also considered when generating recommendations.

### pH

pH represents the acidity or alkalinity of the water.

The backend uses pH values when generating parameter-specific recommendations.

### Turbidity

Measured in NTU.

Turbidity indicates the presence of suspended particles in water. The recommendation logic provides additional suggestions when turbidity reaches higher levels.

### Total Dissolved Solids (TDS)

Measured in ppm.

TDS represents the concentration of dissolved substances in the water. The recommendation logic provides additional suggestions when TDS reaches higher levels.

> **Note:** The current prediction backend uses these four parameters only. Although the AquaSense hardware can collect additional sensor parameters, they are not currently used as inputs to this CNN-LSTM prediction API.

---

## 🧠 Explainable AI Components

### SHAP

AquaSense uses SHAP-based analysis to explain individual predictions.

The backend generates SHAP values for:

* Temperature
* pH
* Turbidity
* TDS

These values are used to determine the relative influence of each feature on the prediction.

### Feature Importance

For each prediction, the backend generates feature-importance information based on SHAP values.

The detailed analysis endpoint also identifies:

* The most influential feature
* A ranking of features according to their SHAP contribution

### Explanation Summary

The `/predict` endpoint provides an explanation summary together with feature importance and recommendations.

The `/explain` endpoint provides a more detailed SHAP analysis.

---

## 💡 Recommendation System

The backend generates recommendations according to the predicted water quality and the observed parameter values.

### Polluted Classification

When the model classifies water as `POLLUTED`, the recommendation system can provide suggestions related to:

* Testing for specific contaminants
* Avoiding consumption until treatment and retesting
* Regular monitoring
* Parameter-specific treatment or corrective actions

### Clean Classification

When the model classifies water as `CLEAN`, the system can provide:

* Confirmation of the classification
* Preventive monitoring suggestions
* Trend-monitoring recommendations
* Source-water protection suggestions

The recommendations are generated by the backend logic and should be considered as system-generated guidance rather than a replacement for laboratory water-quality testing.

---

## 🛠️ Installation and Setup

### Install Dependencies

From the backend directory:

```bash
pip install -r requirements.txt
```

### Main Libraries

* **TensorFlow** — CNN-LSTM model execution
* **SHAP** — Explainable AI analysis
* **Flask** — REST API framework
* **Flask-CORS** — Cross-origin request support
* **Scikit-learn** — Data preprocessing
* **NumPy** — Numerical operations
* **Pandas** — Data handling
* **Joblib** — Loading the trained scaler

### Model Files

The backend uses the following trained model files:

```text
cnnlstm_model.h5
aqua_sense_scaler.pkl
```

These files are used by `app.py` to load the trained CNN-LSTM model and the feature scaler.

---

## 🧪 Testing

The backend repository currently contains:

```text
test_backend_logic.py
```

Run it with:

```bash
python test_backend_logic.py
```

The test file contains backend logic tests related to prediction processing and water-quality classification.

---

## 📈 Example Usage

### Python Client

The Flask server runs locally on port `5000`.

Example request:

```python
import requests

response = requests.post(
    "http://localhost:5000/predict",
    json={
        "temperature": 25.0,
        "ph": 7.2,
        "turbidity": 1.5,
        "tds": 120.0
    }
)

data = response.json()

print("Prediction:", data.get("status"))
print("Probability:", data.get("probability"))
print("Feature Importance:", data.get("explainable_ai", {}).get("feature_importance"))
print("Recommendations:", data.get("explainable_ai", {}).get("recommendations"))
```

### Example Response Structure

The actual `/predict` endpoint follows this general structure:

```json
{
    "success": true,
    "prediction": 0,
    "probability": 0.1234,
    "status": "CLEAN",
    "model_version": "cnnlstm_v1.0",
    "timestamp": "2026-01-01T12:00:00",
    "input_data": {
        "temperature": 25.0,
        "ph": 7.2,
        "turbidity": 1.5,
        "tds": 120.0
    },
    "explainable_ai": {
        "feature_importance": {},
        "recommendations": [],
        "explanation_summary": {}
    },
    "message": "Prediction with AI explanations completed successfully"
}
```

The exact SHAP values, recommendations, and explanation content vary according to the input and model output.

---

## 🔍 Detailed `/explain` Response

The `/explain` endpoint returns a structure containing:

```json
{
    "success": true,
    "detailed_analysis": {
        "prediction_result": {
            "class": 0,
            "probability": 0.1234,
            "status": "CLEAN"
        },
        "feature_analysis": {},
        "input_parameters": {
            "temperature": 25.0,
            "ph": 7.2,
            "turbidity": 1.5,
            "tds": 120.0
        },
        "recommendations": [],
        "shap_summary": {
            "most_influential_feature": {},
            "feature_ranking": []
        },
        "model_info": {
            "model_type": "CNN-LSTM",
            "explanation_method": "SHAP DeepExplainer",
            "background_samples": 0
        }
    },
    "timestamp": "2026-01-01T12:00:00",
    "message": "Detailed SHAP analysis completed successfully"
}
```

The example values above are illustrative. Actual SHAP values, rankings, recommendations, and timestamps depend on the input and model execution.

---

## 🚀 Running the Server

From the backend directory:

```bash
python app.py
```

The Flask application runs on:

```text
http://localhost:5000
```

The application is configured to listen on port `5000`.

When started, the backend attempts to:

1. Load the CNN-LSTM model.
2. Load the feature scaler.
3. Initialize the SHAP explainer.
4. Start the Flask API.

Available endpoints:

```text
GET  /health
GET  /model/info
POST /predict
POST /explain
```

---

## 📊 Model Information

The current backend identifies the model as:

```text
Model: CNN-LSTM Water Quality Classifier
Version: cnnlstm_v1.0
```

### Input Features

```text
Temperature
pH
Turbidity
TDS
```

### Output Classes

```text
CLEAN (0)
POLLUTED (1)
```

### Reported Test-Dataset Accuracy

```text
100% (Test Dataset)
```

This is the value currently reported by the backend's `/model/info` endpoint. It is specific to the test dataset used during development and should not be presented as a guarantee of real-world performance.

---

## 🔧 Configuration

The backend uses:

* A trained CNN-LSTM model
* A saved feature scaler
* SHAP DeepExplainer
* Background data for SHAP analysis

The SHAP component uses background samples defined in the backend to generate feature-attribution explanations.

The backend also contains parameter-specific recommendation logic for temperature, pH, turbidity, and TDS.

---

## 🔍 Troubleshooting

### Model or Scaler Not Loading

Check that the following files are available in the expected backend/model location:

```text
cnnlstm_model.h5
aqua_sense_scaler.pkl
```

### SHAP Analysis Problems

The backend checks whether the model, scaler, and SHAP explainer are available before processing prediction or explanation requests.

If any required component is unavailable, the API returns an error response.

### Invalid Input

The API expects the following four fields:

```text
temperature
ph
turbidity
tds
```

Missing required fields result in an error response.

---

## 🚀 Future Enhancements

Potential future improvements include:

* Additional water-quality parameters
* More extensive model validation using real-world sensor data
* Model retraining with additional field data
* Improved prediction performance evaluation
* Additional explainability techniques
* Expanded monitoring and alert capabilities
* Integration improvements between the backend, Firebase, and mobile application

---

## 📄 Project Context

The backend is one component of the **AquaSense: AI-Powered IoT System for Public Water Quality Monitoring & Predictive Alerts** project.

The overall system combines:

```text
Water Quality Sensors
        ↓
ESP32 Sensor Node
        ↓
LoRa Communication
        ↓
ESP32 Receiver / Base Station
        ↓
Wi-Fi
        ↓
Firebase
        ↓
Flutter Mobile Application
        ↓
AI Prediction & Explainable Analysis
```

The backend provides the Python/Flask API layer for CNN-LSTM prediction and SHAP-based explanation.

---

## 📌 Important Note

The current backend prediction model uses **Temperature, pH, Turbidity, and TDS** as its four input features. Other sensors may be part of the broader AquaSense hardware system, but they are not currently used by this CNN-LSTM prediction API.
