import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Get all users to check if email already exists (since we can't query by email without index)
      final snapshot = await _database.child('users').get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map;
        for (var userEntry in users.entries) {
          Map<dynamic, dynamic> userData = userEntry.value as Map;
          if (userData['email'] == email) {
            return {'success': false, 'message': 'User with this email already exists'};
          }
        }
      }
      
      // Hash the password
      String hashedPassword = _hashPassword(password);
      
      // Create user data
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': hashedPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      
      // Save to database
      final newUserRef = _database.child('users').push();
      await newUserRef.set(userData);
      
      return {
        'success': true,
        'message': 'Registration successful',
        'userId': newUserRef.key,
        'userData': userData
      };
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: ${e.toString()}'};
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Hash the password to compare
      String hashedPassword = _hashPassword(password);
      
      // Get all users to find user by email (since we can't query by email without index)
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) {
        return {'success': false, 'message': 'User not found'};
      }
      
      // Find user by email
      Map<dynamic, dynamic> users = snapshot.value as Map;
      String? userId;
      Map<dynamic, dynamic>? userData;
      
      for (var userEntry in users.entries) {
        Map<dynamic, dynamic> currentUserData = userEntry.value as Map;
        if (currentUserData['email'] == email) {
          userId = userEntry.key.toString();
          userData = currentUserData;
          break;
        }
      }
      
      if (userData == null) {
        return {'success': false, 'message': 'User not found'};
      }
      
      // Verify password
      if (userData['password'] != hashedPassword) {
        return {'success': false, 'message': 'Invalid password'};
      }
      
      // Check if user is active
      if (userData['isActive'] == false) {
        return {'success': false, 'message': 'Account is deactivated'};
      }
      
      return {
        'success': true,
        'message': 'Login successful',
        'userId': userId,
        'userData': userData
      };
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }
  
  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Find user by email
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) {
        return {'success': false, 'message': 'User not found'};
      }
      
      Map<dynamic, dynamic> users = snapshot.value as Map;
      String? userId;
      Map<dynamic, dynamic>? userData;
      
      for (var userEntry in users.entries) {
        Map<dynamic, dynamic> currentUserData = userEntry.value as Map;
        if (currentUserData['email'] == email) {
          userId = userEntry.key.toString();
          userData = currentUserData;
          break;
        }
      }
      
      if (userData == null) {
        return {'success': false, 'message': 'User not found'};
      }
      
      // Hash the new password
      String hashedPassword = _hashPassword(newPassword);
      
      // Update password in database
      await _database.child('users/$userId/password').set(hashedPassword);
      
      return {
        'success': true,
        'message': 'Password reset successful',
        'userId': userId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Password reset failed: ${e.toString()}'};
    }
  }
  
  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) {
        return false;
      }
      
      Map<dynamic, dynamic> users = snapshot.value as Map;
      
      for (var userEntry in users.entries) {
        Map<dynamic, dynamic> userData = userEntry.value as Map;
        if (userData['email'] == email) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
