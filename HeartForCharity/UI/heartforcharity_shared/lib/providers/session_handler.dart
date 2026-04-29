/// Per-app integration point for the shared [BaseProvider].
///
/// Each app implements this and registers an instance via
/// [BaseProvider.sessionHandler] at startup, so the shared HTTP layer can
/// access the current auth token, attempt token refresh on 401 responses,
/// clear the session, and route the user to the app's login screen when
/// refresh fails.
abstract class SessionHandler {
  String? get token;
  Future<bool> tryRefresh();
  Future<void> clearSession();
  void redirectToLogin();
}
