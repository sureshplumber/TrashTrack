import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/waste_report.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _category = 'Plastic';
  bool _isUrgent = false;
  bool _isLocating = false;
  bool _isUploading = false;

  double? _latitude;
  double? _longitude;
  String? _base64Image;

  final ImagePicker _picker = ImagePicker();

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
    _locationController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _locationController.removeListener(_onFieldChanged);
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  String _generateCaseId() {
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return 'CMP-$rand';
  }

  /// Whether the submit button should be enabled.
  /// Required fields: location, and at least one evidence source (Photo or GPS).
  bool get _isFormValid {
    final hasLocation = _locationController.text.trim().isNotEmpty;
    final hasPhoto = _base64Image != null && _base64Image!.isNotEmpty;
    final hasGPS = _latitude != null && _longitude != null;
    return hasLocation && (hasPhoto || hasGPS);
  }

  Future<void> _fetchGPSLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable GPS in system settings.'),
              backgroundColor: AppColors.statusUrgent,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied. You can manually enter the address below.'),
                backgroundColor: AppColors.statusUrgent,
              ),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please type landmark address manually.'),
              backgroundColor: AppColors.statusUrgent,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locationController.text.trim().isEmpty) {
          _locationController.text = "GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
        }
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Captured: Lat ${_latitude!.toStringAsFixed(4)}, Lng ${_longitude!.toStringAsFixed(4)}'),
            backgroundColor: AppColors.statusResolved,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not obtain location: ${e.toString()}'),
            backgroundColor: AppColors.statusUrgent,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        String base64Image = base64Encode(bytes);
        setState(() {
          _base64Image = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera/Gallery access error: ${e.toString()}'),
            backgroundColor: AppColors.statusUrgent,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.citizenCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attach Waste Photo Evidence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryTextLight),
              title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.primaryTextLight)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryTextLight),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.primaryTextLight)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_isFormValid) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseService.currentUser;
      final userId = user?.uid ?? '';
      final userProfile = user != null ? await FirebaseService.getUserProfile(user.uid) : null;
      final userName = userProfile?.name ?? user?.displayName ?? user?.email ?? 'Citizen User';

      final reportId = _generateCaseId();

      final newReport = WasteReport(
        id: reportId,
        userId: userId,
        userName: userName,
        location: _locationController.text.trim(),
        category: _category,
        isUrgent: _isUrgent,
        status: 'Pending',
        latitude: _latitude,
        longitude: _longitude,
        imageBase64: _base64Image,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );

      await FirebaseService.createReport(newReport, _base64Image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint #$reportId submitted successfully!'),
            backgroundColor: AppColors.statusResolved,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: AppColors.statusUrgent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.citizenBackground,
      appBar: AppBar(
        title: const Text('File Waste Complaint', style: TextStyle(color: AppColors.primaryTextDark)),
        backgroundColor: AppColors.primaryTextLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Evidence Section
              const Text(
                '1. Photo Evidence',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _isUploading ? null : _showImageSourceDialog,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.citizenCardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _base64Image != null ? AppColors.primaryTextLight : AppColors.borderLight,
                        width: _base64Image != null ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: _base64Image != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(base64Decode(_base64Image!), width: 160, height: 160, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryTextLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primaryTextDark, size: 18),
                                    onPressed: _showImageSourceDialog,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 40, color: AppColors.primaryTextLight),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add Photo',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryTextLight),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Camera / Gallery',
                                style: TextStyle(fontSize: 11, color: AppColors.secondaryTextLight),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Location Field with Inline GPS Button
              const Text(
                '2. Precise Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                enabled: !_isUploading,
                style: const TextStyle(color: AppColors.primaryTextLight),
                decoration: InputDecoration(
                  labelText: 'Landmark / Street Address',
                  labelStyle: const TextStyle(color: AppColors.primaryTextLight),
                  hintText: 'e.g. 12th Main Road, Indiranagar',
                  hintStyle: const TextStyle(color: AppColors.secondaryTextLight, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.citizenCardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.statusUrgent),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.citizenBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTextLight),
                            )
                          : const Icon(Icons.my_location, color: AppColors.primaryTextLight),
                      onPressed: _isUploading ? null : _fetchGPSLocation,
                      tooltip: 'Detect GPS Location',
                    ),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please specify location/landmark' : null,
              ),

              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 12, color: AppColors.primaryTextLight),
                      const SizedBox(width: 4),
                      Text(
                        'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Category, Notes, Urgency Switch
              const Text(
                '3. Category & Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                style: const TextStyle(color: AppColors.primaryTextLight),
                decoration: InputDecoration(
                  labelText: 'Waste Category',
                  labelStyle: const TextStyle(color: AppColors.primaryTextLight),
                  filled: true,
                  fillColor: AppColors.citizenCardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category, color: AppColors.primaryTextLight),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: _isUploading
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
              ),

              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                enabled: !_isUploading,
                maxLines: 3,
                style: const TextStyle(color: AppColors.primaryTextLight),
                decoration: InputDecoration(
                  labelText: 'Notes / Additional Details (Optional)',
                  labelStyle: const TextStyle(color: AppColors.primaryTextLight),
                  hintText: 'Describe issue details, volume, or hazards...',
                  hintStyle: const TextStyle(color: AppColors.secondaryTextLight, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.citizenCardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.citizenCardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                        SizedBox(width: 8),
                        Text(
                          'Mark as High Urgency Priority',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryTextLight),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isUrgent,
                      activeThumbColor: AppColors.statusUrgent,
                      onChanged: _isUploading ? null : (val) => setState(() => _isUrgent = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Helper message if required fields missing
              if (!_isFormValid)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusUrgent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.statusUrgent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.statusUrgent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location + at least one evidence source (Photo or GPS) required to submit.',
                          style: TextStyle(fontSize: 11, color: AppColors.statusUrgent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isUploading) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.citizenCardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTextLight),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Saving report to Cloud Firestore...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTextLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Submit Button (disabled until required fields are valid)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTextLight,
                    disabledBackgroundColor: AppColors.secondaryTextLight.withValues(alpha: 0.3),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isUploading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded, color: AppColors.primaryTextDark),
                  label: _isUploading
                      ? const Text(
                          'UPLOADING...',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTextDark),
                        )
                      : const Text(
                          'SUBMIT COMPLAINT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTextDark, letterSpacing: 0.5),
                        ),
                  onPressed: (_isFormValid && !_isUploading) ? _submitForm : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}