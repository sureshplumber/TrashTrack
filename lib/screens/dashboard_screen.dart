import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_image.dart';
import 'add_report_screen.dart';
import 'edit_report_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = 'All'; // 'All', 'In Progress', 'Resolved'
  String _scopeFilter = 'Community'; // 'Community' or 'Mine'
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseService.currentUser;
    if (user != null) {
      final profile = await FirebaseService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _withdrawReport(WasteReport report) {
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
              backgroundColor: AppColors.statusUrgent,
              foregroundColor: AppColors.primaryTextDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.deleteReport(report.id);
            },
            child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<WasteReport> _filterReports(List<WasteReport> reports, String currentUserId) {
    var filtered = reports;

    if (_scopeFilter == 'Mine') {
      filtered = filtered.where((r) => r.userId == currentUserId).toList();
    }

    if (_activeTab == 'Resolved') {
      filtered = filtered.where((r) => r.status.toLowerCase() == 'resolved').toList();
    } else if (_activeTab == 'In Progress') {
      filtered = filtered.where((r) => r.status.toLowerCase() == 'in progress').toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final userId = user?.uid ?? '';
    final displayName = _userProfile?.name ?? user?.displayName ?? user?.email ?? 'Citizen User';

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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
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
              accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTextDark)),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: AppColors.secondaryTextDark)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppColors.citizenBackground,
                child: Icon(Icons.person, color: AppColors.primaryTextLight, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.primaryTextLight),
              title: const Text('Complaints Feed', style: TextStyle(color: AppColors.primaryTextLight, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo, color: AppColors.primaryTextLight),
              title: const Text('File New Complaint', style: TextStyle(color: AppColors.primaryTextLight, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReportScreen()),
                );
              },
            ),
            const Divider(color: AppColors.borderLight),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.statusUrgent),
              title: const Text('Log Out', style: TextStyle(color: AppColors.statusUrgent, fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<WasteReport>>(
        stream: FirebaseService.getPublicReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTextLight));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading reports: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.statusUrgent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final reports = snapshot.data ?? [];
          final filtered = _filterReports(reports, userId);

          final resolvedCount = reports.where((r) => r.status.toLowerCase() == 'resolved').length;
          final inProgressCount = reports.where((r) => r.status.toLowerCase() == 'in progress').length;

          return Column(
            children: [
              // Top Community Action & Stats Banner
              _buildHeaderBanner(
                totalCount: reports.length,
                inProgressCount: inProgressCount,
                resolvedCount: resolvedCount,
              ),

              // Filter Tabs Bar
              _buildFilterTabs(reports.length),

              // Complaints Feed List View
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final report = filtered[index];
                          return _buildCitizenReportCard(report);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTextLight,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo, color: AppColors.primaryTextDark),
        label: const Text(
          'REPORT WASTE SPOT',
          style: TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReportScreen()),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner({
    required int totalCount,
    required int inProgressCount,
    required int resolvedCount,
  }) {
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Attach photo evidence & GPS coordinates to notify BBMP crews.',
                        style: TextStyle(color: AppColors.secondaryTextDark, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTextDark,
                    foregroundColor: AppColors.primaryTextLight,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddReportScreen()),
                    );
                  },
                  child: const Text('FILE REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildCounter('Total Reports', totalCount.toString(), Icons.assignment, color: AppColors.primaryTextDark)),
              Container(height: 20, width: 1, color: Colors.white24),
              Expanded(child: _buildCounter('In Progress', inProgressCount.toString(), Icons.hourglass_bottom, color: AppColors.statusInProgress)),
              Container(height: 20, width: 1, color: Colors.white24),
              Expanded(child: _buildCounter('Resolved ✅', resolvedCount.toString(), Icons.task_alt, color: AppColors.statusResolved)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, String count, IconData icon, {required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.secondaryTextDark, fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildScopeChip('Community', 'All Community'),
              const SizedBox(width: 8),
              _buildScopeChip('Mine', 'My Reports'),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabChip('All', 'All Statuses'),
                const SizedBox(width: 8),
                _buildTabChip('In Progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildTabChip('Resolved', 'Resolved ✅'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip(String scopeKey, String label) {
    final isSelected = _scopeFilter == scopeKey;
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
          setState(() => _scopeFilter = scopeKey);
        }
      },
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditReportScreen(report: report)),
        );
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
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    report.id,
                    style: TextStyle(fontSize: 10, color: statusTextColor, fontWeight: FontWeight.bold),
                  ),
                  if (report.isUrgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusUrgent,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: buildReportImage(
                            report.imageBase64,
                            width: 85,
                            height: 85,
                            fallbackWidget: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.delete_outline, color: AppColors.primaryTextLight, size: 30),
                                SizedBox(height: 2),
                                Text('Photo', style: TextStyle(fontSize: 10, color: AppColors.secondaryTextLight)),
                              ],
                            ),
                          ),
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
                                Flexible(
                                  child: Container(
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.statusUrgent, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.location,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primaryTextLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
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
                                  Expanded(
                                    child: Text(
                                      'GPS: ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primaryTextLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
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
                      Flexible(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(color: AppColors.primaryTextLight),
                          ),
                          icon: const Icon(Icons.info_outline, size: 16, color: AppColors.primaryTextLight),
                          label: Text(
                            isResolved ? 'View Details (Locked)' : 'Edit Details',
                            style: const TextStyle(fontSize: 11, color: AppColors.primaryTextLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditReportScreen(report: report),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.statusUrgent),
                          label: const Text('Withdraw', style: TextStyle(fontSize: 11, color: AppColors.statusUrgent), overflow: TextOverflow.ellipsis),
                          onPressed: () => _withdrawReport(report),
                        ),
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
          overflow: TextOverflow.ellipsis,
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
