import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init failed (e.g. platform not configured yet)
    // App will still launch so the UI is visible
    debugPrint('Firebase init error: $e');
  }
  runApp(const KalmadoApp());
}

class KalmadoApp extends StatelessWidget {
  const KalmadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KALMADO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
