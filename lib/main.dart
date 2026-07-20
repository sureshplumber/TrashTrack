import 'package:flutter/material.dart';
import 'services/local_storage.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/official_portal_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrashTrackApp());
}

class TrashTrackApp extends StatefulWidget {
  const TrashTrackApp({super.key});

  @override
  State<TrashTrackApp> createState() => _TrashTrackAppState();
}

class _TrashTrackAppState extends State<TrashTrackApp> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF331D0A), // Deep Espresso
        scaffoldBackgroundColor: const Color(0xFFF4E2CD), // Linen/Cream
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF331D0A),
          foregroundColor: Color(0xFFF4E2CD),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF331D0A),
          primary: const Color(0xFF331D0A), // Primary Dark
          secondary: const Color(0xFF3A5A40), // Eco Accent Olive Forest
          error: const Color(0xFFB84A39), // Urgent Alert Terracotta Red
          surface: const Color(0xFFFAF4EC), // Surface Cards Soft Warm White
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF331D0A), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFF331D0A), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF331D0A)),
          bodyMedium: TextStyle(color: Color(0xFF331D0A)),
        ),
      ),
      home: FutureBuilder<Map<String, String?>?>(
        future: LocalStorageService.getActiveUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF4E2CD),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF331D0A))),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return LoginScreen(onLoginSuccess: _refresh);
          }

          final role = snapshot.data!['role'];
          if (role == 'official') {
            return const OfficialPortalScreen();
          }

          return const DashboardScreen();
        },
      ),
    );
  }
}