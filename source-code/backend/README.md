# AquaSense Python Backend

Flask API server for water quality prediction using a CNN-LSTM model with SHAP-based explainable AI.

## 🚀 Setup Instructions

### Prerequisites

* Python 3.8 or higher
* Trained CNN-LSTM model (`cnnlstm_model.h5`)
* Scaler file (`aqua_sense_scaler.pkl`)

### Installation

1. **Navigate to the backend directory**

```bash
cd backend
```

2. **Create a virtual environment**

```bash
python -m venv venv
```

**Windows:**

```bash
venv\Scripts\activate
```

**Linux/Mac:**

```bash
source venv/bin/activate
```

3. **Install dependencies**

```bash
pip install -r requirements.txt
```

4. **Place the model files**

Copy the following files into the backend directory:

* `cnnlstm_model.h5`
* `aqua_sense_scaler.pkl`

5. **Run the server**

```bash
python app.py
```

The server runs on port `5000`.

## 📡 API Endpoints

### Health Check

```text
GET /health
```

Example response:

```json
{
  "status": "healthy",
  "timestamp": "2024-01-24T11:30:00.000000",
  "model_loaded": true,
  "scaler_loaded": true,
  "shap_explainer_loaded": true
}
```

### Water Quality Prediction

```text
POST /predict
```

Request body:

```json
{
  "temperature": 25.0,
  "ph": 7.2,
  "turbidity": 2.5,
  "tds": 320,
  "timestamp": "2024-01-24T11:30:00.000000"
}
```

The current backend uses four input features:

* Temperature
* pH
* Turbidity
* TDS

Example response:

```json
{
  "success": true,
  "prediction": 0,
  "probability": 0.0012,
  "status": "CLEAN",
  "model_version": "cnnlstm_v1.0",
  "timestamp": "2024-01-24T11:30:00.000000"
}
```

### Model Information

```text
GET /model/info
```

The endpoint provides information about:

* Model type
* Model version
* Input features
* Output classes
* Model/scaler loading status
* Explainable AI availability

## 🔧 Configuration

### Server

The Flask backend runs on port `5000`.

### Mobile App Configuration

The mobile application communicates with the backend through the prediction service.

For local development, replace the placeholder backend address with the address of the computer running the Flask server:

```dart
final String _backendUrl =
    'http://YOUR_BACKEND_IP:5000/predict';
```

The backend health endpoint uses:

```text
http://YOUR_BACKEND_IP:5000/health
```

Do not commit private/local network addresses to the public repository.

## 🐛 Troubleshooting

### Common Issues

**1. Model Loading Error**

* Ensure `cnnlstm_model.h5` is available.
* Check TensorFlow version compatibility.

**2. Scaler Loading Error**

* Ensure `aqua_sense_scaler.pkl` is available.
* Check scikit-learn version compatibility.

**3. Connection Refused**

* Check that the Flask server is running.
* Check that port `5000` is available.
* Verify the backend address used by the mobile application.
* Check firewall settings if required.

**4. CORS Issues**

* Flask-CORS is included in the project.
* Check that the backend is running correctly.

### Testing the API

Health check:

```bash
curl http://YOUR_BACKEND_IP:5000/health
```

Prediction request:

```bash
curl -X POST http://YOUR_BACKEND_IP:5000/predict \
-H "Content-Type: application/json" \
-d '{"temperature": 25.0, "ph": 7.2, "turbidity": 2.5, "tds": 320}'
```

## 📊 Model Details

* **Architecture:** CNN-LSTM Neural Network
* **Input Features:** Temperature, pH, Turbidity, TDS
* **Output:** Binary classification (0 = Clean, 1 = Polluted)
* **Model Version:** `cnnlstm_v1.0`
* **Explainability:** SHAP-based feature analysis

## 🔍 Explainable AI

The backend uses SHAP to analyze the contribution of the input parameters to the model prediction.

The system provides:

* Feature importance
* SHAP values
* Impact interpretation
* Water-quality recommendations
* Explanation summaries

## 🔒 Security

The GitHub version does not contain:

* Wi-Fi credentials
* Firebase authentication credentials
* Private API credentials
* Local network addresses

For production deployment, additional security measures should be implemented.

## 📝 Logs

The server provides logs for:

* Model loading status
* Prediction requests and results
* Error messages
* SHAP analysis
* Server status

## 🚀 Production Deployment

For production use:

1. Use a production WSGI server such as Gunicorn or uWSGI.
2. Implement proper authentication and authorization.
3. Use HTTPS.
4. Configure rate limiting.
5. Implement proper logging.
6. Monitor server performance.
7. Store configuration and secrets securely.
