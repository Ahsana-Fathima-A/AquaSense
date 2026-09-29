from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import joblib
import tensorflow as tf
from datetime import datetime
import os
import shap
import pandas as pd

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global variables for model, scaler, and SHAP explainer
model = None
scaler = None
explainer = None
background_data = None

def load_model_and_scaler():
    """Load the CNN-LSTM model and scaler"""
    global model, scaler, explainer, background_data
    try:
        # Load the trained model
        model = tf.keras.models.load_model("cnnlstm_model.h5")
        
        # Load the scaler
        scaler = joblib.load("aqua_sense_scaler.pkl")
        
        # Create background data for SHAP explainer
        # Generate some representative background data
        background_data = np.array([
            [25.0, 7.0, 5.0, 100],   # Clean water example
            [30.0, 8.5, 15.0, 300],  # Moderately polluted
            [35.0, 6.0, 25.0, 500],  # Polluted water example
            [20.0, 7.5, 3.0, 50],    # Very clean water
            [28.0, 8.0, 10.0, 200]   # Slightly polluted
        ])
        
        # Scale background data
        background_scaled = scaler.transform(background_data)
        
        # Reshape for CNN-LSTM input
        background_reshaped = background_scaled.reshape(background_scaled.shape[0], background_scaled.shape[1], 1)
        
        # Initialize SHAP explainer using GradientExplainer for better compatibility
        explainer = shap.GradientExplainer(model, background_reshaped)
        
        print("✅ Model, scaler, and SHAP explainer loaded successfully")
        return True
    except Exception as e:
        print(f"❌ Error loading model/scaler/explainer: {e}")
        return False

def prepare_input_data(temperature, ph, turbidity, tds):
    """Prepare input data for the model"""
    try:
        # Normalize turbidity values between 60-80 to 10-20 range
        if 60 <= turbidity <= 80:
            # Linear mapping: 60-80 -> 10-20
            # Formula: new_value = 10 + (old_value - 60) * (20-10) / (80-60)
            turbidity = 10 + (turbidity - 60) * 10 / 20
        
        # Create feature array in the correct order (matching code.ipynb model)
        features = np.array([[temperature, ph, turbidity, tds]])
        
        # Scale the features
        features_scaled = scaler.transform(features)
        
        # Reshape for CNN-LSTM input (samples, timesteps, features)
        features_reshaped = features_scaled.reshape(features_scaled.shape[0], features_scaled.shape[1], 1)
        
        return features_reshaped
    except Exception as e:
        print(f"❌ Error preparing input data: {e}")
        return None

def make_prediction(features):
    """Make prediction using the loaded model"""
    try:
        # Make prediction
        prediction_prob = model.predict(features)[0][0]
        prediction_class = 1 if prediction_prob >= 0.2 else 0
        
        return prediction_class, float(prediction_prob)
    except Exception as e:
        print(f"❌ Error making prediction: {e}")
        return None, None

def get_shap_explanation(features, feature_names):
    """Generate SHAP values for explanation"""
    try:
        # Get SHAP values
        shap_values = explainer.shap_values(features)
        
        # Handle different SHAP output formats
        if isinstance(shap_values, list):
            # For binary classification, take the second element (class 1 - polluted)
            if len(shap_values) > 1:
                shap_values = shap_values[1]
            else:
                shap_values = shap_values[0]
        
        # Ensure shap_values is a numpy array
        if not isinstance(shap_values, np.ndarray):
            shap_values = np.array(shap_values)
        
        # Reshape to get the feature values (remove timestep and channel dimensions)
        if len(shap_values.shape) > 2:
            # Average across timesteps and take the first channel
            shap_values = np.mean(shap_values, axis=1)
            if len(shap_values.shape) > 1:
                shap_values = shap_values[:, 0]
        else:
            shap_values = shap_values.flatten()
        
        # Create feature importance dictionary
        feature_importance = {}
        for i, name in enumerate(feature_names):
            if i < len(shap_values):
                feature_importance[name] = {
                    'shap_value': float(shap_values[i]),
                    'impact': 'increases pollution risk' if shap_values[i] > 0 else 'decreases pollution risk'
                }
            else:
                feature_importance[name] = {
                    'shap_value': 0.0,
                    'impact': 'no significant impact'
                }
        
        return feature_importance
    except Exception as e:
        print(f"❌ Error generating SHAP explanation: {e}")
        # Return default values if SHAP fails
        return {
            'Temperature': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
            'pH': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
            'Turbidity': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
            'TDS': {'shap_value': 0.0, 'impact': 'analysis unavailable'}
        }

def generate_recommendations(feature_importance, input_data, prediction_class):
    """Generate recommendations based on SHAP values and prediction"""
    recommendations = []
    
    if prediction_class == 1:  # Polluted
        recommendations.append("⚠️ **Water Quality Alert**: The water is classified as POLLUTED and requires immediate attention.")
        
        # Analyze each feature based on SHAP values
        for feature, importance in feature_importance.items():
            if importance['shap_value'] > 0.1:  # Significant positive contribution to pollution
                value = input_data[feature.lower().replace(' ', '_')]
                
                if feature == 'Temperature':
                    if value > 30:
                        recommendations.append(f"🌡️ **High Temperature** ({value}°C): Reduces dissolved oxygen. Consider shading or cooling mechanisms.")
                    elif value < 20:
                        recommendations.append(f"🌡️ **Low Temperature** ({value}°C): May affect biological processes. Monitor for seasonal changes.")
                
                elif feature == 'pH':
                    if value > 8.5:
                        recommendations.append(f"🧪 **High pH** ({value}): Indicates alkaline conditions. Consider adding acidic neutralizers.")
                    elif value < 6.5:
                        recommendations.append(f"🧪 **Low pH** ({value}): Indicates acidic conditions. Consider adding alkaline neutralizers.")
                    else:
                        recommendations.append(f"🧪 **pH Level** ({value}): Within acceptable range but contributing to pollution risk.")
                
                elif feature == 'Turbidity':
                    if value > 10:
                        recommendations.append(f"💧 **High Turbidity** ({value} NTU): Suspended particles present. Implement filtration systems.")
                    elif value > 5:
                        recommendations.append(f"💧 **Moderate Turbidity** ({value} NTU): Some suspended particles. Consider sedimentation.")
                
                elif feature == 'TDS':
                    if value > 300:
                        recommendations.append(f"🧂 **High TDS** ({value} ppm): High dissolved solids. Consider reverse osmosis or distillation.")
                    elif value > 200:
                        recommendations.append(f"🧂 **Moderate TDS** ({value} ppm): Elevated dissolved solids. Monitor source water.")
        
        # General recommendations for polluted water
        recommendations.extend([
            "🔬 **Immediate Actions**: Test for specific contaminants (heavy metals, bacteria, chemicals).",
            "🚱 **Usage Advisory**: Avoid consumption until water is treated and retested.",
            "📊 **Monitoring**: Implement regular testing schedule (daily for critical applications)."
        ])
    
    else:  # Clean
        recommendations.append("✅ **Water Quality Good**: The water is classified as CLEAN and generally safe for use.")
        
        # Even for clean water, provide maintenance recommendations
        for feature, importance in feature_importance.items():
            if importance['shap_value'] < -0.1:  # Significant negative contribution (helpful for cleanliness)
                value = input_data[feature.lower().replace(' ', '_')]
                recommendations.append(f"✨ **{feature}** ({value}): This parameter is contributing positively to water quality.")
        
        # General maintenance recommendations
        recommendations.extend([
            "🔄 **Preventive Maintenance**: Continue regular monitoring to maintain water quality.",
            "📈 **Trend Analysis**: Track parameter changes over time to detect early degradation.",
            "🛡️ **Protection**: Implement source water protection measures."
        ])
    
    return recommendations

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None,
        'shap_explainer_loaded': explainer is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Main prediction endpoint with SHAP explanations and recommendations"""
    try:
        # Check if model is loaded
        if model is None or scaler is None or explainer is None:
            return jsonify({
                'success': False,
                'message': 'Model, scaler, or SHAP explainer not loaded'
            }), 500
        
        # Get JSON data from request
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'message': 'No JSON data received'
            }), 400
        
        # Extract sensor values (excluding ORP to match code.ipynb model)
        required_fields = ['temperature', 'ph', 'turbidity', 'tds']
        
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        temperature = float(data['temperature'])
        ph = float(data['ph'])
        turbidity = float(data['turbidity'])
        tds = float(data['tds'])
        
        # Prepare input data
        features = prepare_input_data(temperature, ph, turbidity, tds)
        
        if features is None:
            return jsonify({
                'success': False,
                'message': 'Error preparing input data'
            }), 500
        
        # Make prediction
        prediction_class, prediction_prob = make_prediction(features)
        
        if prediction_class is None:
            return jsonify({
                'success': False,
                'message': 'Error making prediction'
            }), 500
        
        # Generate SHAP explanation
        feature_names = ['Temperature', 'pH', 'Turbidity', 'TDS']
        feature_importance = get_shap_explanation(features, feature_names)
        
        # Ensure we have valid feature importance
        if feature_importance is None:
            feature_importance = {
                'Temperature': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'pH': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'Turbidity': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'TDS': {'shap_value': 0.0, 'impact': 'analysis unavailable'}
            }
        
        # Prepare input data dictionary for recommendations
        input_data = {
            'temperature': temperature,
            'ph': ph,
            'turbidity': turbidity,
            'tds': tds
        }
        
        # Generate recommendations
        recommendations = generate_recommendations(feature_importance, input_data, prediction_class)
        
        # Create explanation summary
        feature_contributions = []
        for name, imp in feature_importance.items():
            feature_contributions.append(f"{name} ({imp['shap_value']:.3f})")
        explanation_summary = f"Model prediction based on feature contributions: {', '.join(feature_contributions)}"
        
        # Prepare response
        response = {
            'success': True,
            'prediction': int(prediction_class),
            'probability': float(prediction_prob),
            'status': 'CLEAN' if prediction_class == 0 else 'POLLUTED',
            'model_version': 'cnnlstm_v1.0',
            'timestamp': datetime.now().isoformat(),
            'input_data': {
                'temperature': temperature,
                'ph': ph,
                'turbidity': turbidity,
                'tds': tds
            },
            'explainable_ai': {
                'feature_importance': feature_importance,
                'recommendations': recommendations,
                'explanation_summary': explanation_summary
            },
            'message': 'Prediction with AI explanations completed successfully'
        }
        
        print(f"🔮 Prediction: {response['status']} (Probability: {prediction_prob:.4f})")
        print(f"🧠 SHAP Analysis: {len(feature_importance)} features analyzed")
        print(f"💡 Recommendations: {len(recommendations)} suggestions generated")
        
        return jsonify(response)
        
    except Exception as e:
        print(f"❌ Error in prediction endpoint: {e}")
        return jsonify({
            'success': False,
            'message': f'Internal server error: {str(e)}'
        }), 500

@app.route('/model/info', methods=['GET'])
def model_info():
    """Get model information"""
    return jsonify({
        'model_name': 'CNN-LSTM Water Quality Classifier',
        'model_version': 'cnnlstm_v1.0',
        'input_features': ['Temperature', 'pH', 'Turbidity', 'TDS'],
        'output_classes': ['CLEAN (0)', 'POLLUTED (1)'],
        'accuracy': '100% (Test Dataset)',
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None,
        'shap_explainer_loaded': explainer is not None,
        'explainable_ai_enabled': True,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/explain', methods=['POST'])
def explain():
    """Detailed SHAP analysis endpoint"""
    try:
        # Check if model is loaded
        if model is None or scaler is None or explainer is None:
            return jsonify({
                'success': False,
                'message': 'Model, scaler, or SHAP explainer not loaded'
            }), 500
        
        # Get JSON data from request
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'message': 'No JSON data received'
            }), 400
        
        # Extract sensor values
        required_fields = ['temperature', 'ph', 'turbidity', 'tds']
        
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        temperature = float(data['temperature'])
        ph = float(data['ph'])
        turbidity = float(data['turbidity'])
        tds = float(data['tds'])
        
        # Prepare input data
        features = prepare_input_data(temperature, ph, turbidity, tds)
        
        if features is None:
            return jsonify({
                'success': False,
                'message': 'Error preparing input data'
            }), 500
        
        # Make prediction
        prediction_class, prediction_prob = make_prediction(features)
        
        if prediction_class is None:
            return jsonify({
                'success': False,
                'message': 'Error making prediction'
            }), 500
        
        # Generate detailed SHAP explanation
        feature_names = ['Temperature', 'pH', 'Turbidity', 'TDS']
        feature_importance = get_shap_explanation(features, feature_names)
        
        # Ensure we have valid feature importance
        if feature_importance is None:
            feature_importance = {
                'Temperature': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'pH': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'Turbidity': {'shap_value': 0.0, 'impact': 'analysis unavailable'},
                'TDS': {'shap_value': 0.0, 'impact': 'analysis unavailable'}
            }
        
        # Prepare input data dictionary for recommendations
        input_data = {
            'temperature': temperature,
            'ph': ph,
            'turbidity': turbidity,
            'tds': tds
        }
        
        # Generate recommendations
        recommendations = generate_recommendations(feature_importance, input_data, prediction_class)
        
        # Create detailed analysis
        detailed_analysis = {
            'prediction_result': {
                'class': int(prediction_class),
                'probability': float(prediction_prob),
                'status': 'CLEAN' if prediction_class == 0 else 'POLLUTED'
            },
            'feature_analysis': feature_importance,
            'input_parameters': input_data,
            'recommendations': recommendations,
            'shap_summary': {
                'most_influential_feature': max(feature_importance.items(), key=lambda x: abs(x[1]['shap_value'])),
                'feature_ranking': sorted(feature_importance.items(), key=lambda x: abs(x[1]['shap_value']), reverse=True)
            },
            'model_info': {
                'model_type': 'CNN-LSTM',
                'explanation_method': 'SHAP DeepExplainer',
                'background_samples': len(background_data) if background_data is not None else 0
            }
        }
        
        return jsonify({
            'success': True,
            'detailed_analysis': detailed_analysis,
            'timestamp': datetime.now().isoformat(),
            'message': 'Detailed SHAP analysis completed successfully'
        })
        
    except Exception as e:
        print(f"❌ Error in explain endpoint: {e}")
        return jsonify({
            'success': False,
            'message': f'Internal server error: {str(e)}'
        }), 500

if __name__ == '__main__':
    print("🚀 Starting AquaSense Prediction Backend...")
    
    # Load model and scaler
    if load_model_and_scaler():
        print("✅ Backend ready to serve predictions")
    else:
        print("⚠️ Backend starting without model - please check model files")
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)
