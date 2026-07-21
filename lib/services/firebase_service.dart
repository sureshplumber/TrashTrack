import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/waste_report.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // AUTHENTICATION SERVICES
  // ==========================================

  /// Create a new Firebase Auth account and store user profile in Firestore
  static Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = credential.user;
    if (user == null) {
      throw Exception('User creation failed.');
    }

    // Update display name in Firebase Auth
    await user.updateDisplayName(name);

    final profile = UserProfile(
      uid: user.uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
    );

    // Save profile document in 'users' collection
    await _firestore.collection('users').doc(user.uid).set(profile.toMap());

    return profile;
  }

  /// Authenticate user and fetch profile document from Firestore to determine role
  static Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, user.uid);
    } else {
      // Fallback profile if doc doesn't exist yet
      final fallbackProfile = UserProfile(
        uid: user.uid,
        email: user.email ?? email,
        name: user.displayName ?? 'Citizen User',
        role: 'citizen',
      );
      await _firestore.collection('users').doc(user.uid).set(fallbackProfile.toMap());
      return fallbackProfile;
    }
  }

  /// Fetch user profile by UID
  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, uid);
      }
    } catch (_) {}
    return null;
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream listening to auth state changes
  static Stream<User?> getCurrentUserStream() {
    return _auth.authStateChanges();
  }

  /// Get current Firebase Auth user
  static User? get currentUser => _auth.currentUser;

  // ==========================================
  // FIRESTORE REPORT SERVICES
  // ==========================================

  /// Writes report doc directly to Firestore with base64 image data
  static Future<void> createReport(WasteReport report, String? base64Image) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('waste_reports').doc();
      final reportData = report.toMap();
      reportData['id'] = docRef.id;
      reportData['imageBase64'] = base64Image;
      reportData['createdAt'] = DateTime.now().toIso8601String();

      await docRef.set(reportData);
    } catch (e) {
      debugPrint('Error writing report to Firestore: $e');
      rethrow;
    }
  }

  /// Realtime stream of reports created by [userId]
  static Stream<List<WasteReport>> getCitizenReportsStream(String userId) {
    return _firestore
        .collection('waste_reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return WasteReport.fromMap(doc.data(), doc.id);
      }).toList();
      // Client-side sort by createdAt descending
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Realtime stream of ALL public reports for citizens & community
  static Stream<List<WasteReport>> getPublicReportsStream() {
    return _firestore
        .collection('waste_reports')
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return WasteReport.fromMap(doc.data(), doc.id);
      }).toList();
      // Client-side sort by createdAt descending
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Realtime stream of ALL reports for the Official Portal
  static Stream<List<WasteReport>> getAllReportsStream() {
    return _firestore
        .collection('waste_reports')
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return WasteReport.fromMap(doc.data(), doc.id);
      }).toList();
      // Client-side sort by createdAt descending
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Update report status (e.g. Pending -> In Progress -> Resolved)
  static Future<void> updateReportStatus(String reportId, String newStatus) async {
    await _firestore.collection('waste_reports').doc(reportId).update({
      'status': newStatus,
    });
  }

  /// Update report details
  static Future<void> updateReport(WasteReport report) async {
    await _firestore.collection('waste_reports').doc(report.id).update(report.toMap());
  }

  /// Delete document from Firestore
  static Future<void> deleteReport(String reportId) async {
    await _firestore.collection('waste_reports').doc(reportId).delete();
  }
}
