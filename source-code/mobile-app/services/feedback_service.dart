import 'package:firebase_database/firebase_database.dart';

class FeedbackService {
  final DatabaseReference _feedbackRef = FirebaseDatabase.instance.ref('feedback');

  Future<void> submitFeedback(String username, String feedbackText) async {
    try {
      final feedbackData = {
        'username': username,
        'feedback': feedbackText,
        'timestamp': ServerValue.timestamp,
      };
      
      await _feedbackRef.push().set(feedbackData);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      final snapshot = await _feedbackRef.get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> feedbackMap = snapshot.value as Map;
        List<Map<String, dynamic>> feedbackList = [];
        
        feedbackMap.forEach((key, value) {
          feedbackList.add({
            'id': key,
            'username': value['username'] ?? 'Unknown',
            'feedback': value['feedback'] ?? '',
            'timestamp': value['timestamp'] ?? 0,
          });
        });
        
        // Sort by timestamp (newest first)
        feedbackList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        return feedbackList;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch feedback: $e');
    }
  }

  Stream<DatabaseEvent> getFeedbackStream() {
    return _feedbackRef.onValue;
  }
}
