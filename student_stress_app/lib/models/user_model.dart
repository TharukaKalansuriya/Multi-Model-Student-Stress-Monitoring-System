class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final String? department;
  final String? year;
  final String? bio;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
    required this.createdAt,
    this.department,
    this.year,
    this.bio,
  });

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'department': department,
      'year': year,
      'bio': bio,
    };
  }

  // Create UserModel from Firestore JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt() {
      final createdAt = json['createdAt'];
      if (createdAt == null) return DateTime.now();
      
      // Handle Firestore Timestamp
      if (createdAt is DateTime) {
        return createdAt;
      }
      
      // Handle string date
      try {
        return DateTime.parse(createdAt.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: parseCreatedAt(),
      department: json['department'],
      year: json['year'],
      bio: json['bio'],
    );
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? profileImageUrl,
    DateTime? createdAt,
    String? department,
    String? year,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      year: year ?? this.year,
      bio: bio ?? this.bio,
    );
  }
}
