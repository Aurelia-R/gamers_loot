import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trial_app/Screens/login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trial_app/Services/session_service.dart';
import 'package:trial_app/Services/timezone_service.dart';
import 'package:trial_app/Services/notification_service.dart';
import 'package:trial_app/theme/app_theme.dart';
import 'package:trial_app/Screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SessionService().init();
  await TimezoneService.initialize();
  await NotificationService.initialize();
  await Supabase.initialize(
    url: 'https://ygcxtrnldeyllsmtefau.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnY3h0cm5sZGV5bGxzbXRlZmF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MDUxODgsImV4cCI6MjA3NzQ4MTE4OH0._eIPunN7k2_Bjb-8ftYZfgIYxNlFX_kZrLeMJWHdnM4',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService().getUser();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: user == null ? const LoginScreen() : HomeScreen(user: user),
    );
  }
}
