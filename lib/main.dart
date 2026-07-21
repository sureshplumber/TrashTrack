import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/official_portal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const TrashTrackApp());
}

class TrashTrackApp extends StatelessWidget {
  const TrashTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashTrack (binit)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.citizenTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseService.getCurrentUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.citizenBackground,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryTextLight),
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }

          return FutureBuilder<UserProfile?>(
            future: FirebaseService.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.citizenBackground,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTextLight),
                  ),
                );
              }

              final profile = profileSnapshot.data;
              if (profile != null && profile.role == 'official') {
                return const OfficialPortalScreen();
              }

              return const DashboardScreen();
            },
          );
        },
      ),
    );
  }
}