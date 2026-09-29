import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AquaSenseApp());
}

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSense - Water Quality Monitoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/prediction': (context) => const PredictionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
