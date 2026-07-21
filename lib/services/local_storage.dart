import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_report.dart';

class LocalStorageService {
  static const String _keyReports = 'local_waste_reports';
  static const String _keyActiveUser = 'active_user';
  static const String _keyActiveRole = 'active_role';

  // Initial seed data if storage is fresh and empty
  static final List<WasteReport> _initialSeed = [
    WasteReport(
      id: 'CMP-9482A1',
      location: '12th Main Rd, Indiranagar, Bengaluru',
      category: 'Overflowing Bin',
      isUrgent: true,
      status: 'Pending',
      latitude: 12.9784,
      longitude: 77.6408,
      notes: 'Public garbage bin overflowing near bus shelter blocking pedestrian walkway.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    ),
    WasteReport(
      id: 'CMP-7391B4',
      location: '5th Block, Koramangala',
      category: 'Plastic',
      isUrgent: false,
      status: 'In Progress',
      latitude: 12.9352,
      longitude: 77.6245,
      notes: 'Plastic packaging waste dumped on vacant land next to commercial complex.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    ),
    WasteReport(
      id: 'CMP-5102C8',
      location: 'M.G. Road Metro Station Gate 2',
      category: 'E-Waste',
      isUrgent: false,
      status: 'Resolved',
      latitude: 12.9756,
      longitude: 77.6066,
      notes: 'Discarded computer monitors and cables left near sidewalk.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    ),
  ];

  // --- REPORTS CRUD ---

  /// Retrieve all reports serialized as a JSON array string under 'local_waste_reports'.
  /// Guarded with try-catch so corrupted data degrades to an empty/seed list without crashing.
  static Future<List<WasteReport>> getAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if JSON array string exists
      final String? jsonArrayStr = prefs.getString(_keyReports);

      if (jsonArrayStr != null && jsonArrayStr.trim().isNotEmpty) {
        try {
          final dynamic decoded = json.decode(jsonArrayStr);
          if (decoded is List) {
            final List<WasteReport> reports = [];
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                reports.add(WasteReport.fromMap(item));
              } else if (item is Map) {
                reports.add(WasteReport.fromMap(Map<String, dynamic>.from(item)));
              }
            }
            return reports;
          }
        } catch (_) {
          // If JSON array decoding failed, attempt fallback check
        }
      }

      // Check legacy string list fallback if present
      final List<String>? legacyList = prefs.getStringList(_keyReports);
      if (legacyList != null && legacyList.isNotEmpty) {
        final List<WasteReport> reports = [];
        for (final item in legacyList) {
          try {
            reports.add(WasteReport.fromJson(item));
          } catch (_) {}
        }
        if (reports.isNotEmpty) {
          // Re-save as standard JSON array string
          await _saveAllReports(reports);
          return reports;
        }
      }

      // Seed initial data on fresh install or corrupted storage
      await _saveAllReports(_initialSeed);
      return List.from(_initialSeed);
    } catch (e) {
      // Safe fallback if SharedPreferences itself throws an unexpected error
      return List.from(_initialSeed);
    }
  }

  /// Alias for getAllReports() for backward compatibility
  static Future<List<WasteReport>> getReports() => getAllReports();

  /// Private helper to serialize list of reports as JSON array string
  static Future<bool> _saveAllReports(List<WasteReport> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> mapList = reports.map((r) => r.toMap()).toList();
      final String jsonArrayStr = json.encode(mapList);
      return await prefs.setString(_keyReports, jsonArrayStr);
    } catch (_) {
      return false;
    }
  }

  /// Add a new waste report (prepends newest first)
  static Future<void> addReport(WasteReport report) async {
    try {
      final reports = await getAllReports();
      reports.insert(0, report);
      await _saveAllReports(reports);
    } catch (_) {}
  }

  /// Alias for addReport()
  static Future<void> saveReport(WasteReport report) => addReport(report);

  /// Update an existing waste report by ID
  static Future<void> updateReport(WasteReport updatedReport) async {
    try {
      final reports = await getAllReports();
      final index = reports.indexWhere((r) => r.id == updatedReport.id);
      if (index != -1) {
        reports[index] = updatedReport;
        await _saveAllReports(reports);
      }
    } catch (_) {}
  }

  /// Delete a waste report by ID
  static Future<void> deleteReport(String id) async {
    try {
      final reports = await getAllReports();
      reports.removeWhere((r) => r.id == id);
      await _saveAllReports(reports);
    } catch (_) {}
  }

  // --- AUTH SESSION CRUD ---

  /// Set the active user and role in offline local storage
  static Future<bool> setCurrentUser(String emailOrName, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveUser, emailOrName);
      await prefs.setString(_keyActiveRole, role);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Alias for setCurrentUser()
  static Future<bool> loginOrRegisterUser(String email, String role) =>
      setCurrentUser(email, role);

  /// Get the current active user and role
  static Future<Map<String, String?>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString(_keyActiveUser);
      final role = prefs.getString(_keyActiveRole);
      if (user == null || user.trim().isEmpty) return null;
      return {'email': user, 'role': role ?? 'citizen'};
    } catch (_) {
      return null;
    }
  }

  /// Alias for getCurrentUser()
  static Future<Map<String, String?>?> getActiveUser() => getCurrentUser();

  /// Logout active user session (clears active_user + active_role ONLY, never wipes report data)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveUser);
      await prefs.remove(_keyActiveRole);
    } catch (_) {}
  }
}