import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/utils/auth_flow_helper.dart';
import '../theme/app_colors.dart';

class AppSessionService {
  AppSessionService._();

  static final AppSessionService instance = AppSessionService._();

  static const Duration inactivityTimeout = Duration(minutes: 2);

  GoTrueClient get _auth => Supabase.instance.client.auth;

  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _inactivityTimer;
  DateTime? _backgroundedAt;
  bool _isLoggingOut = false;

  void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) {
    _navigatorKey = navigatorKey;
    _scaffoldMessengerKey = scaffoldMessengerKey;
    _authSubscription ??= _auth.onAuthStateChange.listen((data) {
      _handleAuthChange(data.session?.user);
    });

    if (_auth.currentUser != null) {
      markActivity();
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _cancelTimer();
  }

  void _handleAuthChange(User? user) {
    if (user == null) {
      _backgroundedAt = null;
      _cancelTimer();
      return;
    }

    markActivity();
  }

  void markActivity() {
    if (_auth.currentUser == null || _isLoggingOut) {
      return;
    }

    _backgroundedAt = null;
    _cancelTimer();
    _inactivityTimer = Timer(
      inactivityTimeout,
      () => logoutDueToInactivity(),
    );
  }

  void handleLifecycleChange(AppLifecycleState state) {
    if (_auth.currentUser == null || _isLoggingOut) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt != null &&
            DateTime.now().difference(backgroundedAt) >= inactivityTimeout) {
          unawaited(logoutDueToInactivity());
        } else {
          markActivity();
        }
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _backgroundedAt ??= DateTime.now();
        _cancelTimer();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> logoutManually() async {
    await _logout(
      reason: 'You have been logged out.',
      showMessage: true,
    );
  }

  Future<void> logoutDueToInactivity() async {
    await _logout(
      reason: 'Logged out after 2 minutes of inactivity.',
      showMessage: true,
    );
  }

  Future<void> _logout({
    required String reason,
    required bool showMessage,
  }) async {
    if (_isLoggingOut) {
      return;
    }

    if (_auth.currentUser == null) {
      _backgroundedAt = null;
      _cancelTimer();
      return;
    }

    _isLoggingOut = true;
    _backgroundedAt = null;
    _cancelTimer();

    try {
      await AuthFlowHelper.signOut();

      final navigator = _navigatorKey?.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
      }

      if (showMessage) {
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          _scaffoldMessengerKey?.currentState?.showSnackBar(
            SnackBar(
              content: Text(reason),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } catch (_) {
      _scaffoldMessengerKey?.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Unable to complete logout. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}
