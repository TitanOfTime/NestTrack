import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_view.dart';
import 'views/scanner/scanner_view.dart';
import 'views/report/report_view.dart';
import 'views/settings/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NestTrackApp());
}

class NestTrackApp extends StatelessWidget {
  const NestTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NestTrack',
      home: const LoginScreen(),
      routes: {
        '/home': (_) => const HomeView(),
        '/scanner': (_) => const ScannerView(),
        '/report': (_) => const ReportView(),
        '/settings': (_) => const SettingsView(),
      },
    );
  }
}
