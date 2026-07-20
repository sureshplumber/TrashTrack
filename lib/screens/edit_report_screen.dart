import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import '../services/local_storage.dart';

class EditReportScreen extends StatefulWidget {
  final WasteReport report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _location;
  late String _category;
  late bool _isUrgent;
  late String _status;

  final List<String> _categories = [
    'Plastic',
    'E-Waste',
    'Organic',
    'C&D Debris',
    'Overflowing Bin'
  ];

  final List<String> _statuses = ['Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _location = widget.report.location;
    _category = _categories.contains(widget.report.category) ? widget.report.category : 'Plastic';
    _isUrgent = widget.report.isUrgent;
    _status = widget.report.status;
  }

  Future<void> _saveUpdates() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updated = WasteReport(
        id: widget.report.id,
        location: _location,
        category: _category,
        isUrgent: _isUrgent,
        status: _status,
        latitude: widget.report.latitude,
        longitude: widget.report.longitude,
        imageBase64: widget.report.imageBase64,
        notes: widget.report.notes,
        createdAt: widget.report.createdAt,
      );

      await LocalStorageService.updateReport(updated);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E2CD), // Linen/Cream Primary Background
      appBar: AppBar(
        title: const Text('Edit Report Details', style: TextStyle(color: Color(0xFFF4E2CD))),
        backgroundColor: const Color(0xFF331D0A), // Deep Espresso
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _location,
                decoration: InputDecoration(
                  labelText: 'Landmark / Address',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a location' : null,
                onSaved: (val) => _location = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Waste Category',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Resolution Status',
                  labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                  filled: true,
                  fillColor: const Color(0xFFFAF4EC), // Soft Warm White
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _statuses
                    .map((stat) => DropdownMenuItem(value: stat, child: Text(stat)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAD7C0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mark as Urgent Priority', style: TextStyle(fontSize: 16, color: Color(0xFF331D0A))),
                    Switch(
                      value: _isUrgent,
                      activeThumbColor: const Color(0xFFB84A39), // Urgent Terracotta Red
                      onChanged: (val) => setState(() => _isUrgent = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF331D0A), // Deep Espresso
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveUpdates,
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      color: Color(0xFFF4E2CD),
                      fontWeight: FontWeight.bold,
                    ),
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