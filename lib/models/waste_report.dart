import 'dart:convert';

class WasteReport {
  final String id;
  final String location;
  final String category;
  final bool isUrgent;
  String status;
  final double? latitude;
  final double? longitude;
  final String? imageBase64;
  final String? notes;
  final String createdAt;

  WasteReport({
    required this.id,
    required this.location,
    required this.category,
    required this.isUrgent,
    this.status = 'Pending',
    this.latitude,
    this.longitude,
    this.imageBase64,
    this.notes,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  String get description => notes ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'category': category,
      'isUrgent': isUrgent,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'imageBase64': imageBase64,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory WasteReport.fromMap(Map<String, dynamic> map) {
    return WasteReport(
      id: map['id'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? 'Plastic',
      isUrgent: map['isUrgent'] ?? false,
      status: map['status'] ?? 'Pending',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      imageBase64: map['imageBase64'],
      notes: map['notes'] ?? map['description'],
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => json.encode(toMap());

  factory WasteReport.fromJson(String source) =>
      WasteReport.fromMap(json.decode(source));
}