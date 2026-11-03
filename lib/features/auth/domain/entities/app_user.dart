class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? nidaNumber;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.nidaNumber,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    final ca = data['createdAt'];
    DateTime created;
    if (ca is String) {
      created = DateTime.tryParse(ca) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return AppUser(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      nidaNumber: data['nidaNumber'],
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'nidaNumber': nidaNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
