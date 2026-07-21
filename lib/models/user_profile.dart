class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role; // 'citizen' or 'official'

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'name': name,
    'role': role,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      uid: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'citizen',
    );
  }
}
