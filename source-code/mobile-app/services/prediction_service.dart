import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class PredictionService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Replace YOUR_BACKEND_IP with the IP address of the machine
  // running the AquaSense Python backend.
  final String _backendUrl =
      'http://YOUR_BACKEND_IP:5000/predict';

  // Get current sensor readings and make prediction via Python backend
  Future<Map<String, dynamic>?> makePrediction() async {
    try {
      // Get current sensor readings
      final sensorSnapshot =
          await _database.child('sensor_readings').get();

      if (!sensorSnapshot.exists) {
        return {
          'success': false,
          'message': 'No sensor data available'
        };
      }

      Map<dynamic, dynamic> sensorData =
          sensorSnapshot.value as Map;

      // Extract sensor values (excluding ORP to match backend model)
      double temperature =
          double.tryParse(sensorData['temperature'].toString()) ?? 0.0;

      double ph =
          double.tryParse(sensorData['ph'].toString()) ?? 0.0;

      double turbidity =
          double.tryParse(sensorData['turbidity'].toString()) ?? 0.0;

      double tds =
          double.tryParse(sensorData['tds'].toString()) ?? 0.0;

      // Prepare data for Python backend (4 features to match trained model)
      Map<String, dynamic> requestData = {
        'temperature': temperature,
        'ph': ph,
        'turbidity': turbidity,
        'tds': tds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Call Python backend API
      print('Sending request to backend: $_backendUrl');
      print('Request data: ${json.encode(requestData)}');

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 15));

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> predictionResult =
            json.decode(response.body);

        if (predictionResult['success']) {
          // Save prediction to Firebase
          final predictionData = {
            'timestamp': ServerValue.timestamp,
            'sensor_readings': {
              'temperature': temperature,
              'ph': ph,
              'turbidity': turbidity,
              'tds': tds,
            },
            'prediction': predictionResult['prediction'],
            'probability': predictionResult['probability'],
            'status': predictionResult['status'],
            'model_version':
                predictionResult['model_version'] ?? 'cnnlstm_v1.0',
            'backend_response': predictionResult,
          };

          // Save to Prediction node
          final predictionRef =
              _database.child('Prediction').push();

          await predictionRef.set(predictionData);

          // Also update WQI (Water Quality Index)
          await _database
              .child('Prediction/WQI')
              .set(predictionResult['prediction']);

          return {
            'success': true,
            'prediction': predictionResult['prediction'],
            'probability': predictionResult['probability'],
            'status': predictionResult['status'],
            'timestamp': predictionData['timestamp'],
            'sensor_data': requestData,
            'backend_response': predictionResult,
            'message': 'Prediction completed successfully'
          };
        } else {
          return {
            'success': false,
            'message': predictionResult['message'] ??
                'Backend prediction failed'
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Backend server error: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Prediction failed: ${e.toString()}'
      };
    }
  }

  // Get prediction history
  Future<List<Map<String, dynamic>>> getPredictionHistory() async {
    try {
      final snapshot =
          await _database.child('Prediction').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> data =
            snapshot.value as Map;

        List<Map<String, dynamic>> predictions = [];

        // Convert to list and sort by timestamp
        data.forEach((key, value) {
          if (key != 'WQI') {
            Map<String, dynamic> prediction =
                Map<String, dynamic>.from(value);

            prediction['id'] = key;
            predictions.add(prediction);
          }
        });

        // Sort by timestamp (newest first)
        predictions.sort((a, b) {
          int timestampA = a['timestamp'] ?? 0;
          int timestampB = b['timestamp'] ?? 0;

          return timestampB.compareTo(timestampA);
        });

        return predictions;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get current WQI
  Future<int?> getCurrentWQI() async {
    try {
      final snapshot =
          await _database.child('Prediction/WQI').get();

      if (snapshot.exists) {
        return int.tryParse(snapshot.value.toString());
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream for real-time prediction updates
  Stream<Map<String, dynamic>?> getPredictionStream() {
    return _database.child('Prediction').onValue.map((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map;

        return Map<String, dynamic>.from(data);
      }

      return null;
    });
  }

  // Stream for WQI updates
  Stream<int?> getWQIStream() {
    return _database
        .child('Prediction/WQI')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return int.tryParse(
          event.snapshot.value.toString(),
        );
      }

      return null;
    });
  }

  // Test basic internet connectivity
  Future<bool> testInternetConnectivity() async {
    try {
      print('Testing basic internet connectivity...');

      // Test with a public API
      final response = await http
          .get(
            Uri.parse('https://httpbin.org/get'),
          )
          .timeout(const Duration(seconds: 5));

      print(
        'Internet test response status: ${response.statusCode}',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Internet connectivity error: $e');

      return false;
    }
  }

  // Test backend connection
  Future<bool> testBackendConnection() async {
    try {
      const backendHealthUrl =
          'http://YOUR_BACKEND_IP:5000/health';

      print(
        'Testing backend connection to: $backendHealthUrl',
      );

      final response = await http
          .get(
            Uri.parse(backendHealthUrl),
            headers: {
              'Content-Type': 'application/json'
            },
          )
          .timeout(const Duration(seconds: 5));

      print(
        'Backend response status: ${response.statusCode}',
      );

      print(
        'Backend response body: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection error: $e');
      print('Error type: ${e.runtimeType}');

      return false;
    }
  }
}