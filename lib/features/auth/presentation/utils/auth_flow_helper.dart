import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

class AuthFlowHelper {
  AuthFlowHelper._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  static bool isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return false;
    }

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static Future<AuthResponse?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore stale Google sessions and continue with a fresh sign-in.
      }
    }

    GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      return null;
    }

    final res = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
    );

    final user = res.user;
    if (user != null) {
      await createUserProfileIfNeeded(
        user,
        fallbackName: googleUser.displayName,
      );
    }

    return res;
  }

  static Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }

  static Future<void> createUserProfileIfNeeded(
    User user, {
    String? fallbackName,
  }) async {
    final supabase = Supabase.instance.client;
    final existing = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    final metaName = user.userMetadata?['name']?.toString() ??
        user.userMetadata?['full_name']?.toString() ??
        '';
    final trimmedFallbackName = fallbackName?.trim() ?? '';

    final newUser = AppUser(
      uid: user.id,
      name: metaName.isNotEmpty
          ? metaName
          : trimmedFallbackName.isNotEmpty
              ? trimmedFallbackName
              : 'NextGen User',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );

    await supabase.from('users').upsert(newUser.toFirestore());
  }

  static Future<void> sendPasswordResetEmail(String email) {
    return Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  static Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      try {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google sign-out failures.
      }
    }
  }

  static String supabaseErrorMessage(
    AuthException error, {
    bool isGoogleFlow = false,
    bool isPasswordReset = false,
  }) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid email')) {
      return 'Enter a valid email address.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('wrong password')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('user already registered') || msg.contains('already in use')) {
      return 'This email is already registered. Please sign in.';
    }
    if (msg.contains('password should be at least')) {
      return 'The password provided is too weak.';
    }

    if (isGoogleFlow) {
      return 'Google sign-in failed. Please try again.';
    }
    if (isPasswordReset) {
      return 'Could not send the reset email right now. Please try again.';
    }
    return error.message;
  }

  static String firebaseErrorMessage(
    AuthException error, {
    bool isGoogleFlow = false,
    bool isPasswordReset = false,
  }) =>
      supabaseErrorMessage(
        error,
        isGoogleFlow: isGoogleFlow,
        isPasswordReset: isPasswordReset,
      );

  static String googleErrorMessage(Object error) {
    if (error is AuthException) {
      return supabaseErrorMessage(error, isGoogleFlow: true);
    }

    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return 'Google sign-in was cancelled.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google sign-in configuration error. Check Supabase & Google Console setup.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in is unavailable right now. Please try again.';
        default:
          return error.description ??
              'Google sign-in failed. Please try again.';
      }
    }

    if (error is PlatformException) {
      return error.message ?? 'Google sign-in failed. Please try again.';
    }

    return 'Google sign-in failed. Please try again.';
  }
}
