import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/domain/entities/user_profile_details.dart';

class UserProfileStorageService {
  static final UserProfileStorageService _instance =
      UserProfileStorageService._internal();

  factory UserProfileStorageService() => _instance;

  UserProfileStorageService._internal();

  static const String _profilePrefix = 'user_profile_';

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  String get _storageKey => '$_profilePrefix$_userId';

  Future<UserProfileDetails> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final authUser = Supabase.instance.client.auth.currentUser;
    final userName = authUser?.userMetadata?['name'] ??
        authUser?.userMetadata?['full_name'] ??
        '';
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return UserProfileDetails.empty(
        userId: _userId,
        name: userName,
        email: authUser?.email ?? '',
      );
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final profile = UserProfileDetails.fromJson(decoded);
    return profile.copyWith(
      userId: _userId,
      name: profile.name.isEmpty ? userName : profile.name,
      email: authUser?.email ?? profile.email,
    );
  }

  Future<void> saveProfile(UserProfileDetails profile) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = profile
        .copyWith(
          userId: _userId,
          updatedAt: DateTime.now(),
        )
        .toJson();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
