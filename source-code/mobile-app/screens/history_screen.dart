import 'package:flutter/material.dart';
import '../services/prediction_service.dart';
import '../widgets/app_drawer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PredictionService _predictionService = PredictionService();
  
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPredictionHistory();
  }

  Future<void> _fetchPredictionHistory() async {
    final predictions = await _predictionService.getPredictionHistory();
    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
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
      ),
      drawer: const AppDrawer(currentRoute: '/history'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPredictionHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return _buildPredictionCard(prediction);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Prediction History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run some predictions to see them here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/prediction');
            },
            icon: const Icon(Icons.analytics),
            label: const Text('Run Prediction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final isClean = prediction['prediction'] == 0;
    final probability = (prediction['probability'] ?? 0.0) * 100;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isClean ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isClean ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: isClean ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prediction['status'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isClean ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTimestamp(prediction['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Probability bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${probability.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: probability / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isClean ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Sensor readings
            if (prediction['sensor_readings'] != null) ...[
              const Text(
                'Sensor Readings:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildSensorChip('Temperature', '${prediction['sensor_readings']['temperature']}°C', Colors.orange),
                  _buildSensorChip('pH', '${prediction['sensor_readings']['ph']}', Colors.green),
                  _buildSensorChip('Turbidity', '${prediction['sensor_readings']['turbidity']} NTU', Colors.blue),
                  _buildSensorChip('TDS', '${prediction['sensor_readings']['tds']} ppm', Colors.teal),
                ],
              ),
            ],
            
            // Backend response info
            if (prediction['backend_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model: ${prediction['backend_response']['model_version'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
}
