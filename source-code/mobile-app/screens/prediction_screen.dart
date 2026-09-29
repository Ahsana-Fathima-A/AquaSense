import 'package:flutter/material.dart';
import '../services/prediction_service.dart';
import '../services/sensor_service.dart';
import '../widgets/app_drawer.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PredictionService _predictionService = PredictionService();
  final SensorService _sensorService = SensorService();
  
  Map<String, dynamic>? _sensorData;
  Map<String, dynamic>? _lastPrediction;
  int? _currentWQI;
  bool _isPredicting = false;
  bool _isLoading = true;
  bool _backendConnected = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _testBackendConnection();
    _listenToUpdates();
  }

  void _fetchData() async {
    final sensorData = await _sensorService.getSensorReadings();
    final wqi = await _predictionService.getCurrentWQI();
    final predictions = await _predictionService.getPredictionHistory();
    
    setState(() {
      _sensorData = sensorData;
      _currentWQI = wqi;
      _lastPrediction = predictions.isNotEmpty ? predictions.first : null;
      _isLoading = false;
    });
  }

  void _testBackendConnection() async {
    // First test basic internet connectivity
    final hasInternet = await _predictionService.testInternetConnectivity();
    print('Internet connectivity: $hasInternet');
    
    if (!hasInternet) {
      setState(() {
        _backendConnected = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Then test backend connection
    final connected = await _predictionService.testBackendConnection();
    setState(() {
      _backendConnected = connected;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected ? 'Backend connected' : 'Backend not reachable'),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _listenToUpdates() {
    _sensorService.getSensorReadingsStream().listen((data) {
      setState(() {
        _sensorData = data;
      });
    });
    
    _predictionService.getWQIStream().listen((wqi) {
      setState(() {
        _currentWQI = wqi;
      });
    });
  }

  Future<void> _makePrediction() async {
    setState(() {
      _isPredicting = true;
    });

    try {
      final result = await _predictionService.makePrediction();
      
      if (result!['success'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _lastPrediction = result;
          _currentWQI = result['prediction'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text(
          'AquaSense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _backendConnected ? Icons.wifi : Icons.wifi_off,
              color: _backendConnected ? Colors.green : Colors.red,
            ),
            onPressed: _testBackendConnection,
            tooltip: _backendConnected ? 'Backend Connected' : 'Backend Disconnected',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/prediction'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Backend Connection Status
                  _buildConnectionStatusCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Current WQI Card
                  _buildWQICard(),
                  
                  const SizedBox(height: 16),
                  
                  // Sensor Readings Card
                  _buildSensorReadingsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Last Prediction Card
                  if (_lastPrediction != null) _buildLastPredictionCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Predict Button
                  ElevatedButton.icon(
                    onPressed: (_isPredicting || !_backendConnected) ? null : _makePrediction,
                    icon: _isPredicting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(_isPredicting ? 'Predicting...' : 'Run Prediction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _backendConnected ? Colors.blue[700] : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Model Info Card
                  _buildModelInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 4,
      color: _backendConnected ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _backendConnected ? Icons.check_circle : Icons.error,
              color: _backendConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _backendConnected ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    _backendConnected 
                        ? 'Connected to 172.20.21.3:5000'
                        : 'Cannot connect to backend server',
                    style: TextStyle(
                      fontSize: 12,
                      color: _backendConnected ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _testBackendConnection,
              child: const Text('Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWQICard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.water_drop,
              size: 50,
              color: _currentWQI == 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Water Quality Index',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentWQI != null
                  ? (_currentWQI == 0 ? 'CLEAN' : 'POLLUTED')
                  : 'No Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _currentWQI == 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorReadingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Sensor Readings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_sensorData != null) ...[
              _buildSensorRow('Temperature', '${_sensorData!['temperature']}°C', Icons.thermostat, Colors.orange),
              _buildSensorRow('pH', '${_sensorData!['ph']}', Icons.science, Colors.green),
              _buildSensorRow('Turbidity', '${_sensorData!['turbidity']} NTU', Icons.visibility, Colors.blue),
              _buildSensorRow('TDS', '${_sensorData!['tds']} ppm', Icons.opacity, Colors.teal),
            ] else
              const Text('No sensor data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPredictionCard() {
    // Safely extract backend response data
    Map<String, dynamic>? backendResponse;
    Map<String, dynamic>? explainableAI;
    
    try {
      final backendData = _lastPrediction!['backend_response'];
      if (backendData is Map) {
        backendResponse = Map<String, dynamic>.from(backendData);
        
        final explainableData = backendResponse['explainable_ai'];
        if (explainableData is Map) {
          explainableAI = Map<String, dynamic>.from(explainableData);
        }
      }
    } catch (e) {
      print('Error extracting backend response: $e');
    }
    
    return Card(
      elevation: 4,
      color: _lastPrediction!['prediction'] == 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Prediction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _lastPrediction!['prediction'] == 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Status: ${_lastPrediction!['status']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Probability: ${((_lastPrediction!['probability'] ?? 0) * 100).toStringAsFixed(1)}%'),
            if (_lastPrediction!['timestamp'] != null)
              Text('Time: ${DateTime.fromMillisecondsSinceEpoch(int.tryParse(_lastPrediction!['timestamp'].toString()) ?? 0).toString().substring(0, 19)}'),
            
            // Explainable AI Section
            if (explainableAI != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                '🧠 AI Analysis & Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              
              // Feature Importance
              if (explainableAI['feature_importance'] != null) ...[
                const Text(
                  'Feature Impact:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ..._buildFeatureImportanceWidgetsSafe(explainableAI['feature_importance']),
                const SizedBox(height: 12),
              ],
              
              // Recommendations
              if (explainableAI['recommendations'] != null) ...[
                const Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ..._buildRecommendationWidgetsSafe(explainableAI['recommendations']),
              ],
            ],
            
            if (backendResponse != null && explainableAI == null) ...[
              const SizedBox(height: 8),
              Text(
                'Backend Response: ${backendResponse['message'] ?? 'Success'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureImportanceWidgetsSafe(dynamic featureImportanceData) {
    List<Widget> widgets = [];
    
    if (featureImportanceData is Map) {
      final featureImportance = Map<String, dynamic>.from(featureImportanceData);
      
      featureImportance.forEach((feature, importance) {
        try {
          final shapValue = (importance['shap_value'] as num?)?.toDouble() ?? 0.0;
          final impact = importance['impact']?.toString() ?? 'unknown';
          final color = shapValue > 0 ? Colors.red : Colors.green;
          final icon = shapValue > 0 ? Icons.trending_up : Icons.trending_down;
          
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$feature: ${shapValue.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      impact,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          print('Error processing feature $feature: $e');
        }
      });
    }
    
    return widgets;
  }

  List<Widget> _buildRecommendationWidgetsSafe(dynamic recommendationsData) {
    List<Widget> widgets = [];
    
    if (recommendationsData is List) {
      final recommendations = List<dynamic>.from(recommendationsData);
      
      for (int i = 0; i < recommendations.length; i++) {
        final recommendation = recommendations[i].toString();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  List<Widget> _buildFeatureImportanceWidgets(Map<String, dynamic> featureImportance) {
    List<Widget> widgets = [];
    
    featureImportance.forEach((feature, importance) {
      final shapValue = (importance['shap_value'] as num?)?.toDouble() ?? 0.0;
      final impact = importance['impact']?.toString() ?? 'unknown';
      final color = shapValue > 0 ? Colors.red : Colors.green;
      final icon = shapValue > 0 ? Icons.trending_up : Icons.trending_down;
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$feature: ${shapValue.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  impact,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  List<Widget> _buildRecommendationWidgets(List<dynamic> recommendations) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < recommendations.length; i++) {
      final recommendation = recommendations[i].toString();
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: Text('$feature feature will be implemented in the next phase of development.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text('• Model: CNN-LSTM Neural Network'),
            const Text('• Backend: Python Flask API'),
            const Text('• Server: 172.20.21.3:5000'),
            const Text('• Input Features: Temperature, pH, Turbidity, TDS'),
            const Text('• Output: Water Quality Prediction (0=Clean, 1=Polluted)'),
            const Text('• Accuracy: 100% (Test Dataset)'),
            const Text('• Explainable AI: SHAP-based feature analysis'),
            const SizedBox(height: 8),
            Text(
              'Connected to Python backend with loaded CNN-LSTM model and SHAP explainable AI.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
