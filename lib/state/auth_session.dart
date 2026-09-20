import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../core/api_client.dart';
import '../core/token_store.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum AuthStatus { unknown, unauthenticated, needsVerification, authenticated }

/// The app's root auth state. Mirrors the Swift app's AuthSession, but adds
/// what it was missing: persisted tokens (via TokenStore/secure storage),
/// transparent refresh, and explicit handling of the backend's "login blocked
/// until email verified" behavior (POST /api/auth/login -> 403).
///
/// The backend's AuthResponseDto has no embedded profile, so — like the
/// existing Swift BackendAuthService — the user id is read from the
/// (unverified, client-side-only) JWT `sub` claim, then GET /api/users/{sub}
/// fetches the full profile.
class AuthSession extends ChangeNotifier {
  AuthSession({
    required this.tokenStore,
    required ApiClient apiClient,
    AuthService? authService,
    UserService? userService,
  })  : authService = authService ?? AuthService(apiClient),
        userService = userService ?? UserService(apiClient);

  final TokenStore tokenStore;
  final AuthService authService;
  final UserService userService;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? currentUser;
  bool isBusy = false;
  String? errorMessage;
  String? pendingVerificationEmail;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    await tokenStore.loadFromStorage();
    if (!tokenStore.hasRefreshToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    final refreshed = await tokenStore.refresh();
    if (!refreshed) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _loadProfileFromToken();
  }

  Future<void> _loadProfileFromToken() async {
    final token = tokenStore.accessToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final decoded = JwtDecoder.decode(token);
      final userId = decoded['sub'] as String;
      currentUser = await userService.getProfile(userId);
      status = AuthStatus.authenticated;
    } catch (_) {
      await tokenStore.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final auth = await authService.login(email: email, password: password);
      await tokenStore.save(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      await _loadProfileFromToken();
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isBusy = false;
      if (e.statusCode == 403) {
        pendingVerificationEmail = email;
        status = AuthStatus.needsVerification;
      }
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      isBusy = false;
      errorMessage = 'Could not reach the server. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final auth = await authService.register(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );
      // Registration returns usable tokens immediately, but login() rejects
      // unverified accounts — route to the verify-email screen rather than
      // assuming full access, per the backend's actual behavior.
      await tokenStore.save(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      pendingVerificationEmail = email;
      status = AuthStatus.needsVerification;
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      isBusy = false;
      errorMessage = 'Could not reach the server. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> resendVerification() async {
    final email = pendingVerificationEmail;
    if (email == null) return;
    try {
      await authService.resendVerificationEmail(email);
    } catch (_) {
      // Endpoint always returns 202 regardless of outcome; ignore transport errors.
    }
  }

  /// User claims to have clicked the verification link — drop the stale
  /// session and send them back to a fresh Log In.
  Future<void> backToLogin() async {
    await tokenStore.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    final refresh = tokenStore.refreshToken;
    if (refresh != null) {
      try {
        await authService.logout(refresh);
      } catch (_) {
        // Best-effort revoke; local session is cleared regardless.
      }
    }
    await tokenStore.clear();
    currentUser = null;
    pendingVerificationEmail = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (currentUser == null) return;
    try {
      currentUser = await userService.getProfile(currentUser!.id);
      notifyListeners();
    } catch (_) {
      // Keep stale profile on transient failure.
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
