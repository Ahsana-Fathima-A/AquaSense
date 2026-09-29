import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  
  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AquaSense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Water Quality Monitoring',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/home') {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              selected: currentRoute == '/home',
              selectedTileColor: Colors.blue[50],
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Prediction'),
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/prediction') {
                  Navigator.pushReplacementNamed(context, '/prediction');
                }
              },
              selected: currentRoute == '/prediction',
              selectedTileColor: Colors.blue[50],
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/history') {
                  Navigator.pushReplacementNamed(context, '/history');
                }
              },
              selected: currentRoute == '/history',
              selectedTileColor: Colors.blue[50],
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Alerts'),
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/alerts') {
                  Navigator.pushReplacementNamed(context, '/alerts');
                }
              },
              selected: currentRoute == '/alerts',
              selectedTileColor: Colors.blue[50],
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/feedback') {
                  Navigator.pushReplacementNamed(context, '/feedback');
                }
              },
              selected: currentRoute == '/feedback',
              selectedTileColor: Colors.blue[50],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
