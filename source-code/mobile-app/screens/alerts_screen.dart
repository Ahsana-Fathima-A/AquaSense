import 'package:flutter/material.dart';
import '../services/prediction_service.dart';
import '../widgets/app_drawer.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PredictionService _predictionService = PredictionService();
  
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    final predictions = await _predictionService.getPredictionHistory();
    
    // Filter only bad water quality alerts (WQI = 1 = POLLUTED)
    List<Map<String, dynamic>> badAlerts = predictions.where((prediction) {
      return (prediction['prediction'] ?? 0) == 1; // Only show polluted water
    }).map((prediction) {
      return {
        'wqi': prediction['prediction'] ?? 0,
        'status': prediction['status'] ?? 'Unknown',
        'timestamp': prediction['timestamp'],
        'probability': prediction['probability'] ?? 0.0,
        'sensor_readings': prediction['sensor_readings'] ?? {},
      };
    }).toList();
    
    setState(() {
      _alerts = badAlerts;
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
      drawer: const AppDrawer(currentRoute: '/alerts'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _buildAlertCard(alert);
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
            Icons.check_circle,
            size: 80,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Water Quality Alerts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All water quality measurements are within safe limits',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final wqi = alert['wqi'] ?? 0;
    final status = alert['status'] ?? 'Unknown';
    final probability = (alert['probability'] ?? 0.0) * 100;
    final sensorReadings = alert['sensor_readings'] ?? {};
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with alert icon and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Water Quality Alert',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTimestamp(alert['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Alert message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dangerous,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Poor Water Quality Detected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Water quality is below safe standards. Immediate attention required.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Sensor readings that caused the alert
            if (sensorReadings.isNotEmpty) ...[
              const Text(
                'Problematic Readings:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildSensorChip('Temperature', '${sensorReadings['temperature']}°C', Colors.orange),
                  _buildSensorChip('pH', '${sensorReadings['ph']}', Colors.green),
                  _buildSensorChip('Turbidity', '${sensorReadings['turbidity']} NTU', Colors.blue),
                  _buildSensorChip('TDS', '${sensorReadings['tds']} ppm', Colors.teal),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Confidence indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence: ${probability.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: probability / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              ],
            ),
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


  void _showLogoutDialog() {
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
