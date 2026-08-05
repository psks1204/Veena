/// User Profile Model
///
/// Represents the user profile data from the /api/profile endpoint.
class UserProfile {
  final String? id;
  final String? email;
  final String? name;
  final DateTime? birthDate;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? role;

  const UserProfile({
    this.id,
    this.email,
    this.name,
    this.birthDate,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (birthDate != null)
        'birthDate':
            '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (role != null) 'role': role,
    };
  }

  /// Create update payload for PUT /api/profile
  Map<String, dynamic> toUpdatePayload() {
    return {
      'name': name ?? '',
      'birthDate': birthDate != null
          ? '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}'
          : '',
      'latitude': latitude ?? 0,
      'longitude': longitude ?? 0,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? birthDate,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? role,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      role: role ?? this.role,
    );
  }

  /// Display name with fallback
  String get displayName => name?.isNotEmpty == true ? name! : 'User';

  /// User initials for avatar fallback
  String get initials {
    final n = displayName;
    final parts = n.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : 'U';
  }

  /// Formatted birth date
  String? get formattedBirthDate {
    if (birthDate == null) return null;
    return '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
  }

  /// Whether the profile has location set
  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      (latitude != 0 || longitude != 0);

  /// Age in whole years, based on birthDate. Null if birth date is unknown.
  int? get ageInYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Users under 13 are not permitted social features (Reels, My Channel).
  bool get isUnder13 => ageInYears != null && ageInYears! < 13;
}
