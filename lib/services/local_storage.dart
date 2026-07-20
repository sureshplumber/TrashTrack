import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_report.dart';

class LocalStorageService {
  static const String _keyReports = 'local_waste_reports';
  static const String _keyActiveUser = 'active_user';
  static const String _keyActiveRole = 'active_role';

  // Initial demo seed if storage is empty
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
  static Future<List<WasteReport>> getReports() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_keyReports);
    if (jsonList == null || jsonList.isEmpty) {
      // Seed default reports
      final List<String> seedJson = _initialSeed.map((r) => r.toJson()).toList();
      await prefs.setStringList(_keyReports, seedJson);
      return List.from(_initialSeed);
    }
    return jsonList.map((item) => WasteReport.fromJson(item)).toList();
  }

  static Future<void> saveReport(WasteReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports();
    reports.insert(0, report); // Newest first
    final List<String> jsonList = reports.map((r) => r.toJson()).toList();
    await prefs.setStringList(_keyReports, jsonList);
  }

  static Future<void> updateReport(WasteReport updatedReport) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports();
    final index = reports.indexWhere((r) => r.id == updatedReport.id);
    if (index != -1) {
      reports[index] = updatedReport;
      final List<String> jsonList = reports.map((r) => r.toJson()).toList();
      await prefs.setStringList(_keyReports, jsonList);
    }
  }

  static Future<void> deleteReport(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports();
    reports.removeWhere((r) => r.id == id);
    final List<String> jsonList = reports.map((r) => r.toJson()).toList();
    await prefs.setStringList(_keyReports, jsonList);
  }

  // --- AUTH CRUD ---
  static Future<bool> loginOrRegisterUser(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveUser, email);
    await prefs.setString(_keyActiveRole, role);
    return true;
  }

  static Future<Map<String, String?>?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyActiveUser);
    final role = prefs.getString(_keyActiveRole);
    if (email == null) return null;
    return {'email': email, 'role': role};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveUser);
    await prefs.remove(_keyActiveRole);
  }
}