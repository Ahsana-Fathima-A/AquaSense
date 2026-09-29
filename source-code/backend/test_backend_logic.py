import numpy as np
import joblib
import tensorflow as tf

def test_backend_logic():
    """Test the exact same logic as the backend"""
    
    # Load model and scaler exactly like backend
    model = tf.keras.models.load_model("cnnlstm_model.h5")
    scaler = joblib.load("aqua_sense_scaler.pkl")
    
    # Test inputs
    test_cases = [
        {"name": "Clean water", "temp": 26.0, "ph": 7.5, "turbidity": 5.0, "tds": 100.0},
        {"name": "Another clean", "temp": 27.0, "ph": 7.0, "turbidity": 3.0, "tds": 150.0},
        {"name": "Should be polluted", "temp": 30.0, "ph": 5.0, "turbidity": 50.0, "tds": 500.0}
    ]
    
    for test in test_cases:
        print(f"\n=== {test['name']} ===")
        
        # Prepare input exactly like backend
        features = np.array([[test['temp'], test['ph'], test['turbidity'], test['tds']]])
        print(f"Raw input: {features[0]}")
        
        # Scale exactly like backend
        features_scaled = scaler.transform(features)
        print(f"Scaled input: {features_scaled[0]}")
        
        # Reshape exactly like backend
        features_reshaped = features_scaled.reshape(features_scaled.shape[0], features_scaled.shape[1], 1)
        
        # Predict exactly like backend
        prediction_prob = model.predict(features_reshaped, verbose=0)[0][0]
        prediction_class = 1 if prediction_prob >= 0.3 else 0
        
        print(f"Raw probability: {prediction_prob:.6f}")
        print(f"Prediction class: {prediction_class} ({'POLLUTED' if prediction_class == 1 else 'CLEAN'})")

if __name__ == "__main__":
    test_backend_logic()
