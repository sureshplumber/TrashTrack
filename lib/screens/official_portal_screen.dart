import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';
import 'login_screen.dart';

class OfficialPortalScreen extends StatefulWidget {
  const OfficialPortalScreen({super.key});

  @override
  State<OfficialPortalScreen> createState() => _OfficialPortalScreenState();
}

class _OfficialPortalScreenState extends State<OfficialPortalScreen> {
  List<WasteReport> _allReports = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await LocalStorageService.getReports();
    // Sort reverse chronological
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _allReports = data;
      _isLoading = false;
    });
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

  Future<void> _resolveComplaint(WasteReport report) async {
    report.status = 'Resolved';
    await LocalStorageService.updateReport(report);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Case #${report.id} has been MARKED AS RESOLVED ✅',
            style: const TextStyle(color: Color(0xFFF4E2CD), fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF3A5A40), // Eco Accent Olive Forest #3A5A40
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _loadData();
  }

  Future<void> _updateStatus(WasteReport report, String newStatus) async {
    report.status = newStatus;
    await LocalStorageService.updateReport(report);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Case #${report.id} status updated to "$newStatus"',
            style: const TextStyle(color: Color(0xFFF4E2CD)),
          ),
          backgroundColor: const Color(0xFF331D0A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _loadData();
  }

  List<WasteReport> get _filteredReports {
    return _allReports.where((report) {
      // Status filter
      if (_selectedStatusFilter == 'Urgent') {
        if (!report.isUrgent) return false;
      } else if (_selectedStatusFilter != 'All') {
        if (report.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesLocation = report.location.toLowerCase().contains(query);
        final matchesCategory = report.category.toLowerCase().contains(query);
        final matchesId = report.id.toLowerCase().contains(query);
        final matchesStatus = report.status.toLowerCase().contains(query);
        return matchesLocation || matchesCategory || matchesId || matchesStatus;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Analytics counters
    final totalCount = _allReports.length;
    final urgentCount = _allReports.where((r) => r.isUrgent).length;
    final pendingCount = _allReports.where((r) => r.status.toLowerCase() == 'pending').length;
    final inProgressCount = _allReports.where((r) => r.status.toLowerCase() == 'in progress').length;
    final resolvedCount = _allReports.where((r) => r.status.toLowerCase() == 'resolved').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4E2CD), // Linen/Cream Primary Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF331D0A), // Deep Espresso
        leading: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.admin_panel_settings, color: Color(0xFFF4E2CD), size: 28),
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
                color: Color(0xFFF4E2CD),
              ),
            ),
            Text(
              'Government Municipal Clearance & Operational Control',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFFAF4EC),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFF4E2CD)),
            tooltip: 'Refresh Complaints',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFB84A39)),
            tooltip: 'Official Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF331D0A)))
          : Column(
              children: [
                // Top Executive KPI Control Panel (#331D0A background with #F4E2CD labels)
                _buildAnalyticsBanner(
                  total: totalCount,
                  urgent: urgentCount,
                  pending: pendingCount,
                  inProgress: inProgressCount,
                  resolved: resolvedCount,
                ),

                // Search and Filter Controls Bar
                _buildFilterControls(),

                // Header for Complaints List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, size: 20, color: Color(0xFF3A5A40)),
                      const SizedBox(width: 8),
                      Text(
                        'Citizen Complaints Registry (${_filteredReports.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF331D0A),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedStatusFilter != 'All' || _searchQuery.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedStatusFilter = 'All';
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 16, color: Color(0xFF331D0A)),
                          label: const Text('Reset Filters', style: TextStyle(color: Color(0xFF331D0A))),
                        ),
                    ],
                  ),
                ),

                // Complaints List View
                Expanded(
                  child: _filteredReports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filteredReports.length,
                          itemBuilder: (ctx, index) {
                            final report = _filteredReports[index];
                            return _buildOfficialComplaintCard(report);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalyticsBanner({
    required int total,
    required int urgent,
    required int pending,
    required int inProgress,
    required int resolved,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF331D0A), // Primary Dark Deep Espresso
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'Total Logged',
              value: total.toString(),
              icon: Icons.folder_special,
              color: const Color(0xFFF4E2CD),
              bgColor: const Color(0xFF4A2B11),
              filterKey: 'All',
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Urgent Alerts',
              value: urgent.toString(),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFB84A39), // Urgent Alert Terracotta Red #B84A39
              bgColor: const Color(0xFF421C14),
              filterKey: 'Urgent',
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Pending',
              value: pending.toString(),
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFFD97706), // In-Progress Warm Amber
              bgColor: const Color(0xFF4A2B11),
              filterKey: 'Pending',
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'In Progress',
              value: inProgress.toString(),
              icon: Icons.engineering_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFF4A2B11),
              filterKey: 'In Progress',
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Resolved ✅',
              value: resolved.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF86EFAC),
              bgColor: const Color(0xFF3A5A40), // Eco Accent Olive Forest #3A5A40
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
    required Color color,
    required Color bgColor,
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
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4E2CD) : color.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                    color: Color(0xFFF4E2CD), // Linen/Cream
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFAF4EC), // Soft Warm White
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      color: const Color(0xFFFAF4EC),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Color(0xFF331D0A)),
            decoration: InputDecoration(
              hintText: 'Search complaints by Case ID, Location, Category...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF664D38)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF331D0A)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF331D0A)),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF331D0A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEAD7C0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Status Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Urgent', icon: Icons.error_outline, color: const Color(0xFFB84A39)),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', icon: Icons.timer, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', icon: Icons.sync, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', icon: Icons.check_circle, color: const Color(0xFF3A5A40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon, Color? color}) {
    final isSelected = _selectedStatusFilter == label;
    final activeColor = color ?? const Color(0xFF331D0A);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? const Color(0xFFF4E2CD) : activeColor)
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFFF4E2CD) : const Color(0xFF331D0A),
      ),
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? activeColor : const Color(0xFFEAD7C0),
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
    
    // Status color scheme
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (report.status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFFF4E2CD);
        statusBg = const Color(0xFF3A5A40); // Eco Accent Olive Forest #3A5A40
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'in progress':
        statusColor = const Color(0xFFFAF4EC);
        statusBg = const Color(0xFFD97706); // In-Progress Warm Amber #D97706
        statusIcon = Icons.construction_rounded;
        break;
      default: // pending
        statusColor = const Color(0xFFFAF4EC);
        statusBg = const Color(0xFFD97706);
        statusIcon = Icons.pending_actions_rounded;
        break;
    }

    Uint8List? decodedImage;
    if (report.imageBase64 != null && report.imageBase64!.isNotEmpty) {
      try {
        decodedImage = base64Decode(report.imageBase64!);
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFFAF4EC), // Surface Cards Soft Warm White #FAF4EC
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: report.isUrgent ? const Color(0xFFB84A39) : const Color(0xFFEAD7C0),
          width: report.isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Top Header Line of Card with Case ID & Urgency
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: report.isUrgent ? const Color(0xFFFDF2F0) : const Color(0xFFF4E2CD),
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
                    color: const Color(0xFF331D0A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.id,
                    style: const TextStyle(
                      color: Color(0xFFF4E2CD),
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
                      color: const Color(0xFFB84A39), // Urgent Alert Terracotta Red #B84A39
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'HIGH URGENCY',
                          style: TextStyle(
                            color: Colors.white,
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
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        report.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
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
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAD7C0)),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (decodedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(decodedImage, width: 75, height: 75, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFB84A39), size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.location,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF331D0A),
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
                                  color: Color(0xFF331D0A),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (report.notes != null && report.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 22.0),
                              child: Text(
                                'Notes: ${report.notes}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF664D38)),
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
                      avatar: const Icon(Icons.category, size: 14, color: Color(0xFF331D0A)),
                      label: Text('Category: ${report.category}'),
                      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF331D0A)),
                      backgroundColor: const Color(0xFFF4E2CD),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Direct Action Controls: MARK AS RESOLVED (#3A5A40) with #F4E2CD text
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isResolved ? const Color(0xFFF4E2CD) : const Color(0xFFFAF4EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isResolved ? const Color(0xFF3A5A40) : const Color(0xFFEAD7C0),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isResolved) ...[
                        const Icon(Icons.check_circle, color: Color(0xFF3A5A40), size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'RESOLVED & CLOSED ✅',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A5A40),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(color: Color(0xFF331D0A)),
                          ),
                          onPressed: () => _updateStatus(report, 'Pending'),
                          child: const Text('Re-open Case', style: TextStyle(fontSize: 11, color: Color(0xFF331D0A))),
                        ),
                      ] else ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Administrative Action:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF664D38),
                                ),
                              ),
                              if (report.status.toLowerCase() == 'pending')
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _updateStatus(report, 'In Progress'),
                                  child: const Text('Dispatch Crew (In Progress)', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                                ),
                            ],
                          ),
                        ),
                        // Primary MARK AS RESOLVED (#3A5A40) Button with #F4E2CD text
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A5A40), // Eco Accent Olive Forest #3A5A40
                            foregroundColor: const Color(0xFFF4E2CD), // Linen/Cream #F4E2CD text
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle, size: 18, color: Color(0xFFF4E2CD)),
                          label: const Text(
                            'MARK AS RESOLVED',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: Color(0xFFF4E2CD)),
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
          Icon(Icons.assignment_turned_in, size: 64, color: Color(0xFF331D0A)),
          SizedBox(height: 12),
          Text(
            'No matching complaints found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF331D0A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'All municipal sanitation reports cleared by the department.',
            style: TextStyle(fontSize: 12, color: Color(0xFF664D38)),
          ),
        ],
      ),
    );
  }
}