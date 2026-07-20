class WasteReport {
  final int? id;
  final String location;
  final String category;
  final bool isUrgent;
  final String status;

  WasteReport({
    this.id,
    required this.location,
    required this.category,
    required this.isUrgent,
    this.status = 'Pending',
  });

  // Convert model to Map for SQLite insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'category': category,
      'isUrgent': isUrgent ? 1 : 0, // SQLite stores booleans as integers
      'status': status,
    };
  }

  // Convert Map from SQLite query back into WasteReport object
  factory WasteReport.fromMap(Map<String, dynamic> map) {
    return WasteReport(
      id: map['id'] as int?,
      location: map['location'] as String,
      category: map['category'] as String,
      isUrgent: (map['isUrgent'] as int) == 1,
      status: map['status'] as String,
    );
  }
}