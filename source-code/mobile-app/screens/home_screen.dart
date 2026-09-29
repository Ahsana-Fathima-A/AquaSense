import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SensorService _sensorService = SensorService();
  
  // Sensor data
  Map<String, dynamic>? _sensorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    _listenToSensorUpdates();
  }

  void _fetchSensorData() async {
    final data = await _sensorService.getSensorReadings();
    setState(() {
      _sensorData = data;
      _isLoading = false;
    });
  }

  void _listenToSensorUpdates() {
    _sensorService.getSensorReadingsStream().listen((data) {
      if (mounted) {
        setState(() {
          _sensorData = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel any active subscriptions here if needed
    super.dispose();
  }

  String _getSensorValue(String sensorType, String defaultValue) {
    if (_sensorData == null || !_sensorData!.containsKey(sensorType)) {
      return defaultValue;
    }
    return _sensorData![sensorType].toString();
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
      drawer: const AppDrawer(currentRoute: '/home'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 60,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to AquaSense',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Water Quality Monitoring System',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          _buildStatCard(
                            context,
                            'pH Level',
                            '${_getSensorValue('ph', '7.2')}',
                            Icons.science,
                            Colors.green,
                            () => Navigator.pushNamed(context, '/prediction'),
                          ),
                          _buildStatCard(
                            context,
                            'Temperature',
                            '${_getSensorValue('temperature', '25')}°C',
                            Icons.thermostat,
                            Colors.orange,
                            () => Navigator.pushNamed(context, '/prediction'),
                          ),
                          _buildStatCard(
                            context,
                            'Turbidity',
                            '${_getSensorValue('turbidity', '2.5')} NTU',
                            Icons.visibility,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/prediction'),
                          ),
                          _buildStatCard(
                            context,
                            'TDS',
                            '${_getSensorValue('tds', '320')} ppm',
                            Icons.opacity,
                            Colors.teal,
                            () => Navigator.pushNamed(context, '/prediction'),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/history');
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/alerts');
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Alerts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
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
