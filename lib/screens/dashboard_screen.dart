import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';
import '../theme/app_theme.dart';
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
  String _activeUser = 'Resident Citizen';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final userData = await LocalStorageService.getCurrentUser();
    final data = await LocalStorageService.getAllReports();

    // Sort reverse chronological
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _activeUser = userData?['email'] ?? 'Resident Citizen';
        _reports = data;
        _isLoading = false;
      });
    }
  }

  void _withdrawReport(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.citizenCardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Withdraw Complaint',
          style: TextStyle(color: AppColors.primaryTextLight, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to withdraw this waste report? This action cannot be undone.',
          style: TextStyle(color: AppColors.secondaryTextLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryTextLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgentDanger,
              foregroundColor: AppColors.primaryTextDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.deleteReport(id);
              _loadData();
            },
            child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await LocalStorageService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TrashTrackWrapper()),
                (route) => false,
              );
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
      return _reports.where((r) => r.status.toLowerCase() == 'in progress').toList();
    }
    return _reports;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCount = _reports.where((r) => r.status.toLowerCase() == 'resolved').length;
    final inProgressCount = _reports.where((r) => r.status.toLowerCase() == 'in progress').length;

    return Scaffold(
      backgroundColor: AppColors.citizenBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTextLight,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TrashTrack Citizen Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTextDark),
            ),
            Text(
              'Community Waste Monitoring & Resolution Tracking',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryTextDark),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryTextDark),
            tooltip: 'Refresh Feed',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryTextDark),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.citizenBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryTextLight),
              accountName: Text(_activeUser, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTextDark)),
              accountEmail: const Text('Registered Citizen User', style: TextStyle(color: AppColors.secondaryTextDark)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppColors.citizenBackground,
                child: Icon(Icons.person, color: AppColors.primaryTextLight, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.primaryTextLight),
              title: const Text('My Complaints Feed', style: TextStyle(color: AppColors.primaryTextLight, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo, color: AppColors.primaryTextLight),
              title: const Text('File New Complaint', style: TextStyle(color: AppColors.primaryTextLight, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReportScreen()),
                );
                _loadData();
              },
            ),
            const Divider(color: AppColors.borderLight),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.urgentDanger),
              title: const Text('Log Out', style: TextStyle(color: AppColors.urgentDanger, fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTextLight))
          : Column(
              children: [
                // Top Community Action & Stats Banner
                _buildHeaderBanner(inProgressCount: inProgressCount, resolvedCount: resolvedCount),

                // Filter Tabs Bar
                _buildFilterTabs(),

                // Complaints Feed List View
                Expanded(
                  child: _filteredReports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
        backgroundColor: AppColors.primaryTextLight,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo, color: AppColors.primaryTextDark),
        label: const Text(
          'REPORT WASTE SPOT',
          style: TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
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

  Widget _buildHeaderBanner({required int inProgressCount, required int resolvedCount}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryTextLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          // Banner callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryTextDark.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTextDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryTextLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Spotted illegal dumping or overflow?',
                        style: TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Attach photo evidence & GPS coordinates to notify BBMP crews.',
                        style: TextStyle(color: AppColors.secondaryTextDark, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTextDark,
                    foregroundColor: AppColors.primaryTextLight,
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
          const SizedBox(height: 14),
          // Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounter('Total Reports', _reports.length.toString(), Icons.assignment, color: AppColors.primaryTextDark),
              Container(height: 20, width: 1, color: Colors.white24),
              _buildCounter('In Progress', inProgressCount.toString(), Icons.hourglass_bottom, color: AppColors.statusInProgress),
              Container(height: 20, width: 1, color: Colors.white24),
              _buildCounter('Resolved ✅', resolvedCount.toString(), Icons.task_alt, color: AppColors.statusResolved),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, String count, IconData icon, {required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: const TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.secondaryTextDark, fontSize: 10),
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
          _buildTabChip('All', 'All Reports (${_reports.length})'),
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
        color: isSelected ? AppColors.primaryTextDark : AppColors.primaryTextLight,
      ),
      selectedColor: AppColors.primaryTextLight,
      backgroundColor: AppColors.citizenCardSurface,
      side: BorderSide(color: isSelected ? AppColors.primaryTextLight : AppColors.borderLight),
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

    String statusText;
    Color statusBgColor;
    Color statusTextColor = AppColors.primaryTextDark;
    IconData statusIcon;

    if (isResolved) {
      statusText = 'CLEANUP RESOLVED & COMPLETED ✅';
      statusBgColor = AppColors.statusResolved;
      statusIcon = Icons.check_circle;
    } else if (isInProgress) {
      statusText = 'MUNICIPAL CREW DISPATCHED 🛠️';
      statusBgColor = AppColors.statusInProgress;
      statusIcon = Icons.construction;
    } else {
      statusText = 'COMPLAINT PENDING REVIEW ⏳';
      statusBgColor = AppColors.statusInProgress;
      statusIcon = Icons.hourglass_top;
    }

    Uint8List? decodedImage;
    if (report.imageBase64 != null && report.imageBase64!.isNotEmpty) {
      try {
        decodedImage = base64Decode(report.imageBase64!);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditReportScreen(report: report)),
        );
        _loadData();
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: AppColors.citizenCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: isResolved ? AppColors.statusResolved : AppColors.borderLight,
            width: isResolved ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Ribbon
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
                        color: AppColors.urgentDanger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(color: AppColors.primaryTextDark, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Card Body: Image & Details
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Thumbnail
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: AppColors.citizenBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: decodedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.memory(decodedImage, width: 85, height: 85, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.delete_outline, color: AppColors.primaryTextLight, size: 30),
                                  SizedBox(height: 2),
                                  Text('Photo', style: TextStyle(fontSize: 10, color: AppColors.secondaryTextLight)),
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
                                    color: AppColors.citizenBackground,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Text(
                                    report.category,
                                    style: const TextStyle(
                                      color: AppColors.primaryTextLight,
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
                                const Icon(Icons.location_on, color: AppColors.urgentDanger, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.location,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primaryTextLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (report.latitude != null && report.longitude != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.gps_fixed, size: 12, color: AppColors.primaryTextLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GPS: ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryTextLight,
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
                                  color: AppColors.secondaryTextLight,
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

                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: AppColors.primaryTextLight),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16, color: AppColors.primaryTextLight),
                        label: Text(
                          isResolved ? 'View Details (Locked)' : 'Edit Details',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryTextLight),
                        ),
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
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.urgentDanger),
                        label: const Text('Withdraw', style: TextStyle(fontSize: 12, color: AppColors.urgentDanger)),
                        onPressed: () => _withdrawReport(report.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        color: AppColors.citizenBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(step: 1, label: 'Reported', activeStep: currentStep),
          Expanded(
            child: Container(
              height: 3,
              color: currentStep >= 2 ? AppColors.statusInProgress : AppColors.borderLight,
            ),
          ),
          _buildStepIndicator(step: 2, label: 'In Progress', activeStep: currentStep),
          Expanded(
            child: Container(
              height: 3,
              color: currentStep >= 3 ? AppColors.statusResolved : AppColors.borderLight,
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
        ? (step == 3 ? AppColors.statusResolved : AppColors.statusInProgress)
        : AppColors.secondaryTextLight;

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
                ? const Icon(Icons.check, size: 14, color: AppColors.primaryTextDark)
                : Text('$step', style: TextStyle(fontSize: 11, color: stepColor, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? stepColor : AppColors.secondaryTextLight,
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
          Icon(Icons.eco_outlined, size: 64, color: AppColors.primaryTextLight),
          SizedBox(height: 12),
          Text(
            'No waste complaints found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
          ),
          SizedBox(height: 6),
          Text(
            'Spotted garbage or dumping? Tap "REPORT WASTE SPOT" below.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryTextLight),
          ),
        ],
      ),
    );
  }
}

/// Helper wrapper to handle clean navigation restart
class TrashTrackWrapper extends StatelessWidget {
  const TrashTrackWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>?>(
      future: LocalStorageService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.citizenBackground,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryTextLight)),
          );
        }

        final userData = snapshot.data;
        if (userData == null || userData['email'] == null) {
          return LoginScreen(onLoginSuccess: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TrashTrackWrapper()),
            );
          });
        }

        final role = userData['role'];
        if (role == 'official') {
          return const OfficialPortalScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}