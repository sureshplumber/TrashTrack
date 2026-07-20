import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';

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
    'Overflowing Bin'
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateCaseId() {
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return 'CMP-$rand';
  }

  Future<void> _fetchGPSLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please turn on GPS.'),
              backgroundColor: Color(0xFFB84A39),
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
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
              backgroundColor: Color(0xFFB84A39),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locationController.text.isEmpty) {
          _locationController.text = "GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
        }
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Captured: Lat ${_latitude!.toStringAsFixed(4)}, Lng ${_longitude!.toStringAsFixed(4)}'),
            backgroundColor: const Color(0xFF3A5A40), // Eco Accent Olive Forest
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error acquiring GPS: $e')),
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
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF4EC), // Soft Warm White
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
              'Attach Photo of Waste Spot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF331D0A)),
              title: const Text('Take Photo with Camera', style: TextStyle(color: Color(0xFF331D0A))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF331D0A)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Color(0xFF331D0A))),
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
    if (_formKey.currentState!.validate()) {
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
            content: Text('Complaint ${newReport.id} submitted successfully!'),
            backgroundColor: const Color(0xFF3A5A40),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E2CD), // Linen/Cream Primary Background
      appBar: AppBar(
        title: const Text('File Waste Complaint', style: TextStyle(color: Color(0xFFF4E2CD))),
        backgroundColor: const Color(0xFF331D0A), // Deep Espresso Header
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Attachment Section (Square Preview Thumbnail)
              const Text(
                '1. Photo Evidence',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF4EC), // Surface Cards Soft Warm White
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _imageBytes != null ? const Color(0xFF331D0A) : const Color(0xFFEAD7C0),
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
                                  decoration: const BoxDecoration(color: Color(0xFF331D0A), shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFFF4E2CD), size: 18),
                                    onPressed: _showImageSourceDialog,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 40, color: Color(0xFF331D0A)),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add Photo',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF331D0A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Camera / Gallery',
                                style: TextStyle(fontSize: 11, color: Color(0xFF664D38)),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Landmark / Street Address',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  hintText: 'e.g. 12th Main Road, Indiranagar',
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFFB84A39)), // Urgent Terracotta Red
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4E2CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF331D0A)),
                            )
                          : const Icon(Icons.my_location, color: Color(0xFF331D0A)),
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
                      const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF331D0A)),
                      const SizedBox(width: 4),
                      Text(
                        'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Category, Notes, Urgency Switch
              const Text(
                '3. Category & Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF331D0A)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Waste Category',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF331D0A)),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),

              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes / Additional Details (Optional)',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  hintText: 'Describe issue details, volume, or hazards...',
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EC), // Surface Card
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAD7C0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFB84A39)),
                        SizedBox(width: 8),
                        Text(
                          'Mark as High Urgency Priority',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF331D0A)),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isUrgent,
                      activeThumbColor: const Color(0xFFB84A39), // Urgent Terracotta Red #B84A39
                      onChanged: (val) => setState(() => _isUrgent = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF331D0A), // Deep Espresso #331D0A
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFF4E2CD)),
                  label: const Text(
                    'SUBMIT COMPLAINT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF4E2CD), letterSpacing: 0.5),
                  ),
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}