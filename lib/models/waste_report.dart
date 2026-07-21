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

  static const List<String> validCategories = [
    'Plastic',
    'E-Waste',
    'Organic',
    'C&D Debris',
    'Overflowing Bin',
  ];

  static const List<String> validStatuses = [
    'Pending',
    'In Progress',
    'Resolved',
  ];

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

  /// Default-safe parsing factory to ensure [fromMap] never throws on missing/malformed keys.
  factory WasteReport.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return WasteReport(
        id: 'CMP-${DateTime.now().millisecondsSinceEpoch}',
        location: 'Unknown Location',
        category: 'Plastic',
        isUrgent: false,
        status: 'Pending',
      );
    }

    // Safely parse ID
    final rawId = map['id']?.toString().trim();
    final safeId = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : 'CMP-${DateTime.now().millisecondsSinceEpoch}';

    // Safely parse Location
    final rawLoc = map['location']?.toString().trim();
    final safeLocation = (rawLoc != null && rawLoc.isNotEmpty)
        ? rawLoc
        : 'Unspecified Location';

    // Safely parse Category
    final rawCat = map['category']?.toString().trim();
    final safeCategory = (rawCat != null && validCategories.contains(rawCat))
        ? rawCat
        : 'Plastic';

    // Safely parse isUrgent
    final rawUrgent = map['isUrgent'];
    bool safeUrgent = false;
    if (rawUrgent is bool) {
      safeUrgent = rawUrgent;
    } else if (rawUrgent != null) {
      final s = rawUrgent.toString().toLowerCase();
      safeUrgent = s == 'true' || s == '1';
    }

    // Safely parse Status (enforce state machine values: Pending, In Progress, Resolved)
    final rawStatus = map['status']?.toString().trim();
    String safeStatus = 'Pending';
    if (rawStatus != null) {
      for (final valid in validStatuses) {
        if (valid.toLowerCase() == rawStatus.toLowerCase()) {
          safeStatus = valid;
          break;
        }
      }
    }

    // Safely parse Latitude
    final rawLat = map['latitude'];
    double? safeLat;
    if (rawLat is num) {
      safeLat = rawLat.toDouble();
    } else if (rawLat != null) {
      safeLat = double.tryParse(rawLat.toString());
    }

    // Safely parse Longitude
    final rawLng = map['longitude'];
    double? safeLng;
    if (rawLng is num) {
      safeLng = rawLng.toDouble();
    } else if (rawLng != null) {
      safeLng = double.tryParse(rawLng.toString());
    }

    // Safely parse Image Base64
    final rawImg = map['imageBase64']?.toString();
    final safeImage = (rawImg != null && rawImg.isNotEmpty) ? rawImg : null;

    // Safely parse Notes (supporting fallback 'description' key)
    final rawNotes = (map['notes'] ?? map['description'])?.toString();
    final safeNotes = (rawNotes != null && rawNotes.isNotEmpty) ? rawNotes : null;

    // Safely parse CreatedAt
    final rawCreated = map['createdAt']?.toString();
    final safeCreated = (rawCreated != null && rawCreated.isNotEmpty)
        ? rawCreated
        : DateTime.now().toIso8601String();

    return WasteReport(
      id: safeId,
      location: safeLocation,
      category: safeCategory,
      isUrgent: safeUrgent,
      status: safeStatus,
      latitude: safeLat,
      longitude: safeLng,
      imageBase64: safeImage,
      notes: safeNotes,
      createdAt: safeCreated,
    );
  }

  String toJson() => json.encode(toMap());

  factory WasteReport.fromJson(String source) {
    try {
      final dynamic decoded = json.decode(source);
      if (decoded is Map<String, dynamic>) {
        return WasteReport.fromMap(decoded);
      }
    } catch (_) {}
    return WasteReport.fromMap(null);
  }

  WasteReport copyWith({
    String? id,
    String? location,
    String? category,
    bool? isUrgent,
    String? status,
    double? latitude,
    double? longitude,
    String? imageBase64,
    String? notes,
    String? createdAt,
  }) {
    return WasteReport(
      id: id ?? this.id,
      location: location ?? this.location,
      category: category ?? this.category,
      isUrgent: isUrgent ?? this.isUrgent,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageBase64: imageBase64 ?? this.imageBase64,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}