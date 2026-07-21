import 'package:flutter/material.dart';
import 'services/local_storage.dart';
import 'theme/app_theme.dart';
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
  void _refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashTrack (binit)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.citizenTheme,
      home: FutureBuilder<Map<String, String?>?>(
        future: LocalStorageService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.citizenBackground,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryTextLight),
              ),
            );
          }

          final userData = snapshot.data;
          if (userData == null || userData['email'] == null) {
            return LoginScreen(onLoginSuccess: _refreshState);
          }

          final role = userData['role'];
          if (role == 'official') {
            return const OfficialPortalScreen();
          }

          return const DashboardScreen();
        },
      ),
    );
  }
}