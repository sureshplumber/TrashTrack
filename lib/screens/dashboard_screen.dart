import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';
import 'add_report_screen.dart';
import 'edit_report_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<WasteReport> _reports = [];
  bool _isLoading = true;
  String _activeTab = 'All'; // 'All', 'In Progress', 'Resolved'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await LocalStorageService.getReports();
    // Sort reverse chronological order
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _reports = data;
      _isLoading = false;
    });
  }

  void _deleteReport(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF4EC),
        title: const Text(
          'Withdraw Complaint',
          style: TextStyle(color: Color(0xFF331D0A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to withdraw this waste report?',
          style: TextStyle(color: Color(0xFF331D0A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF331D0A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB84A39)), // Terracotta Red
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.deleteReport(id);
              _loadData();
            },
            child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await LocalStorageService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  List<WasteReport> get _filteredReports {
    if (_activeTab == 'Resolved') {
      return _reports.where((r) => r.status.toLowerCase() == 'resolved').toList();
    } else if (_activeTab == 'In Progress') {
      return _reports.where((r) => r.status.toLowerCase() != 'resolved').toList();
    }
    return _reports;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCount = _reports.where((r) => r.status.toLowerCase() == 'resolved').length;
    final inProgressCount = _reports.length - resolvedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E2CD), // Linen/Cream Primary Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF331D0A), // Deep Espresso Header
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TrashTrack Citizen Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF4E2CD)),
            ),
            Text(
              'Community Waste Monitoring & Resolution Tracking',
              style: TextStyle(fontSize: 11, color: Color(0xFFFAF4EC)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFF4E2CD)),
            tooltip: 'Refresh Reports',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF4E2CD)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF4E2CD),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF331D0A)),
              accountName: Text('Registered Citizen', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF4E2CD))),
              accountEmail: Text('citizen@trashtrack.local', style: TextStyle(color: Color(0xFFFAF4EC))),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Color(0xFFF4E2CD),
                child: Icon(Icons.person, color: Color(0xFF331D0A), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF331D0A)),
              title: const Text('My Complaints Feed', style: TextStyle(color: Color(0xFF331D0A), fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo, color: Color(0xFF331D0A)),
              title: const Text('File New Complaint', style: TextStyle(color: Color(0xFF331D0A), fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReportScreen()),
                );
                _loadData();
              },
            ),
            const Divider(color: Color(0xFF331D0A)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB84A39)),
              title: const Text('Log Out', style: TextStyle(color: Color(0xFFB84A39), fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF331D0A)))
          : Column(
              children: [
                // Top Community Header Banner
                _buildCitizenHeaderBanner(inProgressCount: inProgressCount, resolvedCount: resolvedCount),

                // Filter Tabs
                _buildFilterTabs(),

                // Complaints List View
                Expanded(
                  child: _filteredReports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filteredReports.length,
                          itemBuilder: (ctx, index) {
                            final report = _filteredReports[index];
                            return _buildCitizenReportCard(report);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF331D0A), // Primary Dark #331D0A
        elevation: 4,
        icon: const Icon(Icons.add_a_photo, color: Color(0xFFF4E2CD)), // Linen/Cream #F4E2CD
        label: const Text(
          'REPORT WASTE SPOT',
          style: TextStyle(color: Color(0xFFF4E2CD), fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReportScreen()),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildCitizenHeaderBanner({required int inProgressCount, required int resolvedCount}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF331D0A), // Primary Dark Deep Espresso
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          // Action banner callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4E2CD).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4E2CD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF331D0A), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Spotted illegal dumping or overflowing bins?',
                        style: TextStyle(color: Color(0xFFF4E2CD), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload photo evidence & GPS coordinates to notify municipal crews.',
                        style: TextStyle(color: Color(0xFFFAF4EC), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4E2CD),
                    foregroundColor: const Color(0xFF331D0A),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddReportScreen()),
                    );
                    _loadData();
                  },
                  child: const Text('FILE REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCitizenCounter('Total Logged', _reports.length.toString(), Icons.assignment),
              Container(height: 20, width: 1, color: Colors.white24),
              _buildCitizenCounter('In Progress', inProgressCount.toString(), Icons.hourglass_bottom, color: const Color(0xFFD97706)),
              Container(height: 20, width: 1, color: Colors.white24),
              _buildCitizenCounter('Resolved ✅', resolvedCount.toString(), Icons.task_alt, color: const Color(0xFF86EFAC)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenCounter(String label, String count, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFFF4E2CD)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: const TextStyle(color: Color(0xFFF4E2CD), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFFAF4EC), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildTabChip('All', 'All Complaints (${_reports.length})'),
          const SizedBox(width: 8),
          _buildTabChip('In Progress', 'In Progress'),
          const SizedBox(width: 8),
          _buildTabChip('Resolved', 'Resolved ✅'),
        ],
      ),
    );
  }

  Widget _buildTabChip(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFFF4E2CD) : const Color(0xFF331D0A),
      ),
      selectedColor: const Color(0xFF331D0A),
      backgroundColor: const Color(0xFFFAF4EC),
      side: BorderSide(color: isSelected ? const Color(0xFF331D0A) : const Color(0xFFEAD7C0)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _activeTab = tabKey);
        }
      },
    );
  }

  Widget _buildCitizenReportCard(WasteReport report) {
    final bool isResolved = report.status.toLowerCase() == 'resolved';
    final bool isInProgress = report.status.toLowerCase() == 'in progress';

    // Status Styling based on user spec:
    // Eco Accent (Resolved / Cleaned): Olive Forest #3A5A40
    // In-Progress Accent: Warm Amber #D97706
    // Urgent Alert: Terracotta Red #B84A39
    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    if (isResolved) {
      statusText = 'CLEANUP RESOLVED & COMPLETED ✅';
      statusBgColor = const Color(0xFF3A5A40); // Eco Accent Olive Forest #3A5A40
      statusTextColor = const Color(0xFFF4E2CD); // Linen/Cream #F4E2CD
      statusIcon = Icons.check_circle;
    } else if (isInProgress) {
      statusText = 'MUNICIPAL CREW DISPATCHED 🛠️';
      statusBgColor = const Color(0xFFD97706); // Warm Amber #D97706
      statusTextColor = const Color(0xFFFAF4EC);
      statusIcon = Icons.construction;
    } else {
      statusText = 'COMPLAINT PENDING REVIEW ⏳';
      statusBgColor = const Color(0xFFD97706); // Warm Amber #D97706
      statusTextColor = const Color(0xFFFAF4EC);
      statusIcon = Icons.hourglass_top;
    }

    Uint8List? decodedImage;
    if (report.imageBase64 != null && report.imageBase64!.isNotEmpty) {
      try {
        decodedImage = base64Decode(report.imageBase64!);
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFFFAF4EC), // Soft Warm White Surface Card #FAF4EC
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isResolved ? const Color(0xFF3A5A40) : const Color(0xFFEAD7C0),
          width: isResolved ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resolution Status Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusTextColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  report.id,
                  style: TextStyle(fontSize: 10, color: statusTextColor, fontWeight: FontWeight.bold),
                ),
                if (report.isUrgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB84A39), // Urgent Alert Terracotta Red #B84A39
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Card Body: Photo & Details
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Thumbnail Preview
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E2CD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF331D0A).withValues(alpha: 0.2)),
                      ),
                      child: decodedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(decodedImage, width: 85, height: 85, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.delete_outline, color: Color(0xFF331D0A), size: 30),
                                SizedBox(height: 2),
                                Text('Photo', style: TextStyle(fontSize: 10, color: Color(0xFF331D0A))),
                              ],
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E2CD),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF331D0A).withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  report.category,
                                  style: const TextStyle(
                                    color: Color(0xFF331D0A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFB84A39), size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.location,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF331D0A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (report.latitude != null && report.longitude != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF331D0A)),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS: ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF331D0A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (report.notes != null && report.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '"${report.notes}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF664D38),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3-Step Progress Stepper
                _buildStatusProgressBar(report.status),

                const SizedBox(height: 8),

                // Bottom Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFF331D0A)),
                      ),
                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF331D0A)),
                      label: const Text('Edit Details', style: TextStyle(fontSize: 12, color: Color(0xFF331D0A))),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditReportScreen(report: report),
                          ),
                        );
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFB84A39)),
                      label: const Text('Withdraw', style: TextStyle(fontSize: 12, color: Color(0xFFB84A39))),
                      onPressed: () => _deleteReport(report.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar(String status) {
    int currentStep = 1;
    if (status.toLowerCase() == 'in progress') currentStep = 2;
    if (status.toLowerCase() == 'resolved') currentStep = 3;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E2CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAD7C0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(step: 1, label: 'Reported', activeStep: currentStep),
          Expanded(
            child: Container(
              height: 3,
              color: currentStep >= 2 ? const Color(0xFFD97706) : const Color(0xFFC7B39B),
            ),
          ),
          _buildStepIndicator(step: 2, label: 'In Progress', activeStep: currentStep),
          Expanded(
            child: Container(
              height: 3,
              color: currentStep >= 3 ? const Color(0xFF3A5A40) : const Color(0xFFC7B39B),
            ),
          ),
          _buildStepIndicator(step: 3, label: 'Resolved ✅', activeStep: currentStep),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required int step, required String label, required int activeStep}) {
    final bool isCompleted = activeStep >= step;
    final bool isCurrent = activeStep == step;

    Color stepColor = isCompleted
        ? (step == 3 ? const Color(0xFF3A5A40) : const Color(0xFFD97706))
        : const Color(0xFF664D38);

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted ? stepColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: isCurrent ? 2 : 1),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Color(0xFFF4E2CD))
                : Text('$step', style: TextStyle(fontSize: 11, color: stepColor, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? stepColor : const Color(0xFF664D38),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.eco_outlined, size: 64, color: Color(0xFF331D0A)),
          SizedBox(height: 12),
          Text(
            'No waste complaints found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
          ),
          SizedBox(height: 6),
          Text(
            'Spotted garbage or dumping? Tap "REPORT WASTE SPOT" below.',
            style: TextStyle(fontSize: 12, color: Color(0xFF664D38)),
          ),
        ],
      ),
    );
  }
}