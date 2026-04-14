import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseService.instance.startHistoryLogging();
  } catch (e) {
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
      builder: kIsWeb
          ? (context, child) => _MobileWebWrapper(child: child!)
          : null,
      home: const SplashScreen(),
    );
  }
}

class _MobileWebWrapper extends StatelessWidget {
  final Widget child;
  const _MobileWebWrapper({required this.child});

  static const double _mobileWidth = 390;
  static const double _mobileHeight = 844;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD0D8E4),
      body: Center(
        child: Container(
          width: _mobileWidth,
          height: _mobileHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
