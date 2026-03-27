import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_view.dart';
import 'views/scanner/scanner_view.dart';

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
      // Login is the entry point; after auth success, push /home.
      home: const LoginScreen(),
      routes: {
        '/home': (_) => const HomeView(),
        '/scanner': (_) => const ScannerView(),
        // Placeholder – will be replaced with full ReportView in Sprint 2.
        '/report': (ctx) {
          final args =
              ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Product found!\n\n${args?.entries.map((e) => '${e.key}: ${e.value}').join('\n') ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      },
    );
  }
}
