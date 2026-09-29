import 'package:firebase_database/firebase_database.dart';

class SensorService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Get all sensor readings
  Future<Map<String, dynamic>?> getSensorReadings() async {
    try {
      final snapshot = await _database.child('sensor_readings').get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Get specific sensor value
  Future<double?> getSensorValue(String sensorType) async {
    try {
      final snapshot = await _database.child('sensor_readings').child(sensorType).get();
      
      if (snapshot.exists) {
        return double.tryParse(snapshot.value.toString());
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Stream for real-time sensor updates
  Stream<Map<String, dynamic>?> getSensorReadingsStream() {
    return _database.child('sensor_readings').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }
  
  // Stream for specific sensor updates
  Stream<double?> getSensorValueStream(String sensorType) {
    return _database.child('sensor_readings').child(sensorType).onValue.map((event) {
      if (event.snapshot.exists) {
        return double.tryParse(event.snapshot.value.toString());
      }
      return null;
    });
  }
}
