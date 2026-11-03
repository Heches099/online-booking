class UserProfileDetails {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String nidaNumber;
  final int age;
  final String avatarPath;
  final List<String> favoriteRoutes;
  final String preferredLanguage;
  final String preferredCoachClass;
  final bool travelAlertsEnabled;
  final bool biometricLockEnabled;
  final bool shareLiveTripEnabled;
  final DateTime updatedAt;

  const UserProfileDetails({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.nidaNumber,
    required this.age,
    required this.avatarPath,
    required this.favoriteRoutes,
    required this.preferredLanguage,
    required this.preferredCoachClass,
    required this.travelAlertsEnabled,
    required this.biometricLockEnabled,
    required this.shareLiveTripEnabled,
    required this.updatedAt,
  });

  factory UserProfileDetails.empty({
    required String userId,
    String name = '',
    String email = '',
  }) {
    return UserProfileDetails(
      userId: userId,
      name: name,
      email: email,
      phoneNumber: '',
      nidaNumber: '',
      age: 25,
      avatarPath: '',
      favoriteRoutes: const [
        'Dar es Salaam -> Arusha',
        'Dar es Salaam -> Dodoma',
        'Dar es Salaam -> Singida',
      ],
      preferredLanguage: 'English',
      preferredCoachClass: 'Luxury AC Sleeper',
      travelAlertsEnabled: true,
      biometricLockEnabled: false,
      shareLiveTripEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  UserProfileDetails copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNumber,
    String? nidaNumber,
    int? age,
    String? avatarPath,
    List<String>? favoriteRoutes,
    String? preferredLanguage,
    String? preferredCoachClass,
    bool? travelAlertsEnabled,
    bool? biometricLockEnabled,
    bool? shareLiveTripEnabled,
    DateTime? updatedAt,
  }) {
    return UserProfileDetails(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nidaNumber: nidaNumber ?? this.nidaNumber,
      age: age ?? this.age,
      avatarPath: avatarPath ?? this.avatarPath,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredCoachClass: preferredCoachClass ?? this.preferredCoachClass,
      travelAlertsEnabled: travelAlertsEnabled ?? this.travelAlertsEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      shareLiveTripEnabled: shareLiveTripEnabled ?? this.shareLiveTripEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    return UserProfileDetails(
      userId: json['userId']?.toString() ?? 'guest',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      nidaNumber: json['nidaNumber']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 18,
      avatarPath: json['avatarPath']?.toString() ?? '',
      favoriteRoutes:
          List<String>.from(json['favoriteRoutes'] as List? ?? const []),
      preferredLanguage: json['preferredLanguage']?.toString() ?? 'English',
      preferredCoachClass:
          json['preferredCoachClass']?.toString() ?? 'Luxury AC Sleeper',
      travelAlertsEnabled: json['travelAlertsEnabled'] as bool? ?? true,
      biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? false,
      shareLiveTripEnabled: json['shareLiveTripEnabled'] as bool? ?? true,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'nidaNumber': nidaNumber,
      'age': age,
      'avatarPath': avatarPath,
      'favoriteRoutes': favoriteRoutes,
      'preferredLanguage': preferredLanguage,
      'preferredCoachClass': preferredCoachClass,
      'travelAlertsEnabled': travelAlertsEnabled,
      'biometricLockEnabled': biometricLockEnabled,
      'shareLiveTripEnabled': shareLiveTripEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) {
      return 'NG';
    }
    final letters = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? 'NG' : letters;
  }
}
