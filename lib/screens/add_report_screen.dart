import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';
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

  double? _latitude;
  double? _longitude;
  Uint8List? _imageBytes;
  String? _imageBase64;

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
  /// Rule: Required fields are location, category, AND at least one of photo or GPS coordinates.
  bool get _isFormValid {
    final hasLocation = _locationController.text.trim().isNotEmpty;
    final hasPhoto = _imageBase64 != null && _imageBase64!.isNotEmpty;
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
              backgroundColor: AppColors.urgentDanger,
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
                backgroundColor: AppColors.urgentDanger,
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
              backgroundColor: AppColors.urgentDanger,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
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
            backgroundColor: AppColors.urgentDanger,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera/Gallery access error: ${e.toString()}'),
            backgroundColor: AppColors.urgentDanger,
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

    final newReport = WasteReport(
      id: _generateCaseId(),
      location: _locationController.text.trim(),
      category: _category,
      isUrgent: _isUrgent,
      status: 'Pending',
      latitude: _latitude,
      longitude: _longitude,
      imageBase64: _imageBase64,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await LocalStorageService.saveReport(newReport);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint #${newReport.id} submitted successfully!'),
          backgroundColor: AppColors.statusResolved,
        ),
      );
      Navigator.pop(context);
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
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.citizenCardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _imageBytes != null ? AppColors.primaryTextLight : AppColors.borderLight,
                        width: _imageBytes != null ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: _imageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(_imageBytes!, width: 160, height: 160, fit: BoxFit.cover),
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
                style: const TextStyle(color: AppColors.primaryTextLight),
                decoration: InputDecoration(
                  labelText: 'Landmark / Street Address',
                  labelStyle: const TextStyle(color: AppColors.primaryTextLight),
                  hintText: 'e.g. 12th Main Road, Indiranagar',
                  hintStyle: const TextStyle(color: AppColors.secondaryTextLight, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.citizenCardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.urgentDanger),
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
                      onPressed: _fetchGPSLocation,
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
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _category = val);
                  }
                },
              ),

              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
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
                        Icon(Icons.warning_amber_rounded, color: AppColors.urgentDanger),
                        SizedBox(width: 8),
                        Text(
                          'Mark as High Urgency Priority',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryTextLight),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isUrgent,
                      activeThumbColor: AppColors.urgentDanger,
                      onChanged: (val) => setState(() => _isUrgent = val),
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
                    color: AppColors.urgentDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.urgentDanger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.urgentDanger, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location + at least one evidence source (Photo or GPS) required to submit.',
                          style: TextStyle(fontSize: 11, color: AppColors.urgentDanger, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

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
                  icon: const Icon(Icons.send_rounded, color: AppColors.primaryTextDark),
                  label: const Text(
                    'SUBMIT COMPLAINT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTextDark, letterSpacing: 0.5),
                  ),
                  onPressed: _isFormValid ? _submitForm : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}