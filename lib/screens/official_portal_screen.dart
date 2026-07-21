import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_image.dart';
import 'edit_report_screen.dart';
import 'login_screen.dart';

class OfficialPortalScreen extends StatefulWidget {
  const OfficialPortalScreen({super.key});

  @override
  State<OfficialPortalScreen> createState() => _OfficialPortalScreenState();
}

class _OfficialPortalScreenState extends State<OfficialPortalScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  bool _urgentFirstSort = true;

  Future<void> _logout() async {
    await FirebaseService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resolveComplaint(WasteReport report) async {
    await FirebaseService.updateReportStatus(report.id, 'Resolved');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Case #${report.id} MARKED AS RESOLVED ✅',
            style: const TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.statusResolved,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markInProgress(WasteReport report) async {
    await FirebaseService.updateReportStatus(report.id, 'In Progress');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Case #${report.id} updated to IN PROGRESS 🛠️',
            style: const TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.statusInProgress,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<WasteReport> _filterAndSortReports(List<WasteReport> allReports) {
    final filtered = allReports.where((report) {
      // Status & Urgency filter
      if (_selectedStatusFilter == 'Urgent') {
        if (!report.isUrgent) return false;
      } else if (_selectedStatusFilter != 'All') {
        if (report.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // Search query filter (Case ID, Address, Category)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesLocation = report.location.toLowerCase().contains(query);
        final matchesCategory = report.category.toLowerCase().contains(query);
        final matchesId = report.id.toLowerCase().contains(query);
        final matchesStatus = report.status.toLowerCase().contains(query);
        return matchesLocation || matchesCategory || matchesId || matchesStatus;
      }

      return true;
    }).toList();

    // Sort logic: Urgent first (if enabled), then reverse chronological by createdAt
    filtered.sort((a, b) {
      if (_urgentFirstSort) {
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.officialBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.officialBackground,
        leading: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.admin_panel_settings, color: AppColors.primaryTextDark, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BBMP Sanitation Command Center',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.primaryTextDark,
              ),
            ),
            Text(
              'Government Municipal Clearance & Operational Control',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.secondaryTextDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.statusUrgent),
            tooltip: 'Official Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<WasteReport>>(
        stream: FirebaseService.getAllReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTextDark));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading command center feed: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.statusUrgent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allReports = snapshot.data ?? [];

          // Live KPI analytics counters recomputed directly from stream
          final totalCount = allReports.length;
          final urgentCount = allReports.where((r) => r.isUrgent).length;
          final pendingCount = allReports.where((r) => r.status.toLowerCase() == 'pending').length;
          final inProgressCount = allReports.where((r) => r.status.toLowerCase() == 'in progress').length;
          final resolvedCount = allReports.where((r) => r.status.toLowerCase() == 'resolved').length;

          final filteredReports = _filterAndSortReports(allReports);

          return Column(
            children: [
              // Top Executive KPI Control Panel
              _buildKpiBanner(
                total: totalCount,
                urgent: urgentCount,
                pending: pendingCount,
                inProgress: inProgressCount,
                resolved: resolvedCount,
              ),

              // Search & Filters Control Bar
              _buildSearchAndFilterBar(),

              // Subheader with Sort Toggle & Registry Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.statusResolved),
                    const SizedBox(width: 6),
                    Text(
                      'Complaints Registry (${filteredReports.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextDark,
                      ),
                    ),
                    const Spacer(),
                    // Urgent-first sort toggle
                    FilterChip(
                      selected: _urgentFirstSort,
                      showCheckmark: true,
                      checkmarkColor: AppColors.primaryTextDark,
                      avatar: const Icon(Icons.sort, size: 14, color: AppColors.primaryTextDark),
                      label: const Text('Urgent First'),
                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.primaryTextDark),
                      selectedColor: AppColors.statusUrgent.withValues(alpha: 0.4),
                      backgroundColor: AppColors.officialCardSurface,
                      side: const BorderSide(color: AppColors.borderDark),
                      onSelected: (val) => setState(() => _urgentFirstSort = val),
                    ),
                  ],
                ),
              ),

              // Complaints List View (HARD CONSTRAINT - ZERO CREATE/SUBMIT UI ANYWHERE)
              Expanded(
                child: filteredReports.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filteredReports.length,
                        itemBuilder: (ctx, index) {
                          final report = filteredReports[index];
                          return _buildOfficialComplaintCard(report);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiBanner({
    required int total,
    required int urgent,
    required int pending,
    required int inProgress,
    required int resolved,
  }) {
    return Container(
      width: double.infinity,
      color: AppColors.officialBackground,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'Total Logged',
              value: total.toString(),
              icon: Icons.folder_open_outlined,
              accentColor: AppColors.primaryTextDark,
              filterKey: 'All',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'Urgent Alerts',
              value: urgent.toString(),
              icon: Icons.warning_amber_rounded,
              accentColor: AppColors.statusUrgent,
              filterKey: 'Urgent',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'Pending',
              value: pending.toString(),
              icon: Icons.hourglass_top_rounded,
              accentColor: AppColors.statusInProgress,
              filterKey: 'Pending',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'In Progress',
              value: inProgress.toString(),
              icon: Icons.engineering_rounded,
              accentColor: AppColors.statusInProgress,
              filterKey: 'In Progress',
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              title: 'Resolved ✅',
              value: resolved.toString(),
              icon: Icons.check_circle_outline_rounded,
              accentColor: AppColors.statusResolved,
              filterKey: 'Resolved',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
  }) {
    final isSelected = _selectedStatusFilter == filterKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.officialCardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextDark,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryTextDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      color: AppColors.officialCardSurface,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: AppColors.primaryTextDark),
            decoration: InputDecoration(
              hintText: 'Search by Case ID, Location address, or Category...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.secondaryTextDark),
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryTextDark),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.primaryTextDark),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: AppColors.officialBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Urgent', icon: Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', icon: Icons.timer_outlined, color: AppColors.statusInProgress),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', icon: Icons.construction, color: AppColors.statusInProgress),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', icon: Icons.check_circle_outline, color: AppColors.statusResolved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon, Color? color}) {
    final isSelected = _selectedStatusFilter == label;
    final activeColor = color ?? AppColors.primaryTextDark;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? AppColors.primaryTextDark : activeColor)
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryTextDark : AppColors.secondaryTextDark,
      ),
      selectedColor: activeColor.withValues(alpha: 0.4),
      backgroundColor: AppColors.officialBackground,
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.borderDark,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = label;
        });
      },
    );
  }

  Widget _buildOfficialComplaintCard(WasteReport report) {
    final bool isResolved = report.status.toLowerCase() == 'resolved';
    final bool isInProgress = report.status.toLowerCase() == 'in progress';

    Color statusBg;
    IconData statusIcon;

    if (isResolved) {
      statusBg = AppColors.statusResolved;
      statusIcon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      statusBg = AppColors.statusInProgress;
      statusIcon = Icons.construction_rounded;
    } else {
      statusBg = AppColors.statusInProgress;
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.officialCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: report.isUrgent ? AppColors.statusUrgent : AppColors.borderDark,
          width: report.isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Ticket Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: report.isUrgent
                  ? AppColors.statusUrgent.withValues(alpha: 0.2)
                  : AppColors.officialBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.officialCardSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    report.id,
                    style: const TextStyle(
                      color: AppColors.primaryTextDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (report.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusUrgent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber, color: AppColors.primaryTextDark, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            color: AppColors.primaryTextDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: AppColors.primaryTextDark, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        report.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryTextDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.borderDark),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report.imageBase64 != null && report.imageBase64!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildReportImage(
                          report.imageBase64,
                          width: 75,
                          height: 75,
                          fallbackWidget: Container(
                            width: 75,
                            height: 75,
                            color: AppColors.officialBackground,
                            child: const Icon(Icons.broken_image, color: AppColors.statusUrgent, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.statusUrgent, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.location,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTextDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (report.latitude != null && report.longitude != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0, left: 22.0),
                              child: Text(
                                'GPS: ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryTextDark,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (report.userName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0, left: 22.0),
                              child: Text(
                                'Reporter: ${report.userName}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryTextDark),
                              ),
                            ),
                          if (report.notes != null && report.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 22.0),
                              child: Text(
                                'Notes: ${report.notes}',
                                style: const TextStyle(fontSize: 12, color: AppColors.secondaryTextDark),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category, size: 14, color: AppColors.primaryTextDark),
                      label: Text('Category: ${report.category}'),
                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.primaryTextDark),
                      backgroundColor: AppColors.officialBackground,
                      side: const BorderSide(color: AppColors.borderDark),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    const Spacer(),
                    // Inspection Drill-Down Button
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.secondaryTextDark),
                      label: const Text('Inspect Detail', style: TextStyle(fontSize: 11, color: AppColors.secondaryTextDark)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditReportScreen(report: report),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Administrative Action Controls
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.officialBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      if (isResolved) ...[
                        const Icon(Icons.check_circle, color: AppColors.statusResolved, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'RESOLVED & CLOSED ✅',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusResolved,
                            ),
                          ),
                        ),
                      ] else ...[
                        if (report.status.toLowerCase() == 'pending') ...[
                          // Secondary MARK AS IN PROGRESS button (#F59E0B)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusInProgress,
                              foregroundColor: AppColors.primaryTextDark,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.construction, size: 16),
                            label: const Text('MARK IN PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _markInProgress(report),
                          ),
                          const SizedBox(width: 8),
                        ],

                        const Spacer(),

                        // Prominent MARK AS RESOLVED button (#10B981)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusResolved,
                            foregroundColor: AppColors.primaryTextDark,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'MARK AS RESOLVED',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                          ),
                          onPressed: () => _resolveComplaint(report),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assignment_turned_in, size: 64, color: AppColors.primaryTextDark),
          SizedBox(height: 12),
          Text(
            'No matching complaints found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTextDark),
          ),
          SizedBox(height: 6),
          Text(
            'All municipal sanitation reports in this view are cleared.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryTextDark),
          ),
        ],
      ),
    );
  }
}