import 'package:flutter/material.dart';
import 'package:gsmanger/screens/home_screen.dart'; // ✅ updated package name
import 'package:gsmanger/services/settings_service.dart';
import 'package:gsmanger/theme/theme.dart'; // ✅ updated package name

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init(); // Ensure SharedPreferences is initialized
  runApp(const GSManagerApp()); // ✅ new name for clarity
}

class GSManagerApp extends StatelessWidget {
  const GSManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSManager - Georgina Stone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const HomeScreen(), // Update check now handled in HomeScreen
    );
  }
}
