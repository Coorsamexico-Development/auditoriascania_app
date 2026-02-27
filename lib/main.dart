import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/picking_list_screen.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(AuditoriaApp());
}

class AuditoriaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auditoría Scania',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LaunchCoordinator(),
    );
  }
}

class LaunchCoordinator extends StatefulWidget {
  @override
  _LaunchCoordinatorState createState() => _LaunchCoordinatorState();
}

class _LaunchCoordinatorState extends State<LaunchCoordinator> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? PickingListScreen() : LoginScreen();
  }
}
