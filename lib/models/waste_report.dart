import 'package:cloud_firestore/cloud_firestore.dart';

class WasteReport {
  final String id;
  final String userId;
  final String userName;
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
    required this.userId,
    required this.userName,
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
      'userId': userId,
      'userName': userName,
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
  factory WasteReport.fromMap(Map<String, dynamic>? map, [String? docId]) {
    if (map == null) {
      return WasteReport(
        id: docId ?? 'CMP-${DateTime.now().millisecondsSinceEpoch}',
        userId: '',
        userName: 'Anonymous',
        location: 'Unknown Location',
        category: 'Plastic',
        isUrgent: false,
        status: 'Pending',
      );
    }

    // Safely parse ID
    final rawId = docId ?? map['id']?.toString().trim();
    final safeId = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : 'CMP-${DateTime.now().millisecondsSinceEpoch}';

    // Safely parse User ID & Name
    final safeUserId = map['userId']?.toString().trim() ?? '';
    final safeUserName = map['userName']?.toString().trim() ?? 'Citizen User';

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

    // Safely parse Status
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

    // Safely parse Image Base64 (handling legacy imageUrl if present as fallback)
    final rawImg = (map['imageBase64'] ?? map['imageUrl'])?.toString();
    final safeImage = (rawImg != null && rawImg.isNotEmpty) ? rawImg : null;

    // Safely parse Notes
    final rawNotes = (map['notes'] ?? map['description'])?.toString();
    final safeNotes = (rawNotes != null && rawNotes.isNotEmpty) ? rawNotes : null;

    // Safely parse CreatedAt (string or Firestore Timestamp)
    String safeCreated = DateTime.now().toIso8601String();
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      safeCreated = rawCreated.toDate().toIso8601String();
    } else if (rawCreated != null && rawCreated.toString().isNotEmpty) {
      safeCreated = rawCreated.toString();
    }

    return WasteReport(
      id: safeId,
      userId: safeUserId,
      userName: safeUserName,
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

  WasteReport copyWith({
    String? id,
    String? userId,
    String? userName,
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
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
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