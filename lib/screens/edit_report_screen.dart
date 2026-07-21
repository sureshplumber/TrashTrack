import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_image.dart';

class EditReportScreen extends StatefulWidget {
  final WasteReport report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late String _category;
  late bool _isUrgent;
  late String _status;
  
  UserProfile? _userProfile;
  bool _isLoadingRole = true;

  final List<String> _categories = [
    'Plastic',
    'E-Waste',
    'Organic',
    'C&D Debris',
    'Overflowing Bin',
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.report.location);
    _notesController = TextEditingController(text: widget.report.notes ?? '');
    _category = _categories.contains(widget.report.category) ? widget.report.category : 'Plastic';
    _isUrgent = widget.report.isUrgent;
    _status = widget.report.status;
    _fetchUserRole();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseService.currentUser;
    if (user != null) {
      final profile = await FirebaseService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingRole = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  /// Whether editing is permitted on this screen.
  /// Rule:
  /// - Officials use this screen purely as a read-only detail inspector.
  /// - Citizens can edit pre-Resolved tickets (Pending / In Progress). Once Resolved, fields are locked.
  bool get _isEditable {
    if (_userProfile?.role == 'official') return false;
    return _status.toLowerCase() != 'resolved';
  }

  Future<void> _saveChanges() async {
    if (!_isEditable) return;
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.report.copyWith(
      location: _locationController.text.trim(),
      category: _category,
      isUrgent: _isUrgent,
      notes: _notesController.text.trim(),
    );

    await FirebaseService.updateReport(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report details updated successfully.'),
          backgroundColor: AppColors.statusResolved,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfficial = _userProfile?.role == 'official';

    final bgColor = isOfficial ? AppColors.officialBackground : AppColors.citizenBackground;
    final cardColor = isOfficial ? AppColors.officialCardSurface : AppColors.citizenCardSurface;
    final textColor = isOfficial ? AppColors.primaryTextDark : AppColors.primaryTextLight;
    final secondaryTextColor = isOfficial ? AppColors.secondaryTextDark : AppColors.secondaryTextLight;
    final borderColor = isOfficial ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          isOfficial ? 'Ticket Inspector (#${widget.report.id})' : 'Edit Report Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoadingRole
          ? Center(child: CircularProgressIndicator(color: textColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Lock Information Card
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Icon(
                              _isEditable ? Icons.edit_note : Icons.lock_clock,
                              color: _isEditable ? AppColors.statusInProgress : AppColors.statusResolved,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${_status.toUpperCase()}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOfficial
                                        ? 'Official Read-Only Inspector. Resolution actions are taken from the portal.'
                                        : (_isEditable
                                            ? 'Citizen editing permitted for pre-Resolved report.'
                                            : 'Report is Resolved and locked against modification.'),
                                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Photo Evidence Preview if present
                    if (widget.report.imageBase64 != null && widget.report.imageBase64!.isNotEmpty) ...[
                      Text(
                        'Attached Photo Evidence:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildReportImage(
                            widget.report.imageBase64,
                            height: 180,
                            width: double.infinity,
                            fallbackWidget: Container(
                              height: 180,
                              color: cardColor,
                              child: const Icon(Icons.broken_image, color: AppColors.statusUrgent, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location / Landmark Field
                    TextFormField(
                      controller: _locationController,
                      enabled: _isEditable,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Landmark / Street Address',
                        labelStyle: TextStyle(color: textColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a location' : null,
                    ),

                    const SizedBox(height: 14),

                    // GPS Coordinates Display
                    if (widget.report.latitude != null && widget.report.longitude != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.gps_fixed, color: textColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'GPS Coordinates: ${widget.report.latitude!.toStringAsFixed(4)}, ${widget.report.longitude!.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Waste Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Waste Category',
                        labelStyle: TextStyle(color: textColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: _isEditable
                          ? (val) {
                              if (val != null) setState(() => _category = val);
                            }
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // Notes / Description
                    TextFormField(
                      controller: _notesController,
                      enabled: _isEditable,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Notes / Additional Details',
                        labelStyle: TextStyle(color: textColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Urgent Priority Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                              const SizedBox(width: 8),
                              Text(
                                'High Urgency Priority',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isUrgent,
                            activeThumbColor: AppColors.statusUrgent,
                            onChanged: _isEditable ? (val) => setState(() => _isUrgent = val) : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Changes Button (only visible if editable)
                    if (_isEditable)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTextLight,
                            foregroundColor: AppColors.primaryTextDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.save, size: 20),
                          onPressed: _saveChanges,
                          label: const Text(
                            'SAVE CHANGES',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}