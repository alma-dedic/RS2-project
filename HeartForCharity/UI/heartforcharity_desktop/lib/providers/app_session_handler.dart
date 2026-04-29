import 'package:flutter/material.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:heartforcharity_shared/providers/session_handler.dart';
import 'package:heartforcharity_desktop/main.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/screens/login_screen.dart';

class AppSessionHandler implements SessionHandler {
  @override
  String? get token => AuthProvider.token;

  @override
  Future<bool> tryRefresh() => AuthProvider.tryRefresh();

  @override
  Future<void> clearSession() => AuthProvider.clearSession();

  @override
  void redirectToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

void registerAppSessionHandler() {
  BaseProvider.sessionHandler = AppSessionHandler();
}
