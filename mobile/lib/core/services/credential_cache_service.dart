import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCredentials {
  final String email;
  final String password;
  final bool rememberMe;

  const SavedCredentials({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });
}

class CredentialCacheService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String keyEmail = 'raize_cached_email';
  static const String keyPassword = 'raize_cached_password';
  static const String keyRememberMe = 'raize_cached_remember_me';

  static SavedCredentials? _memoryCache;

  static bool get isTestMode {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Saves the athlete's login credentials securely to local storage
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    _memoryCache = SavedCredentials(
      email: email.trim(),
      password: password,
      rememberMe: true,
    );
    if (isTestMode) return;
    try {
      await _storage.write(key: keyEmail, value: email.trim());
      await _storage.write(key: keyPassword, value: password);
      await _storage.write(key: keyRememberMe, value: 'true');
    } catch (_) {}
  }

  /// Retrieves previously remembered credentials if 'Remember Me' was active
  static Future<SavedCredentials?> getSavedCredentials() async {
    if (isTestMode) return _memoryCache;
    try {
      final rememberMe = await _storage.read(key: keyRememberMe);
      if (rememberMe == 'true') {
        final email = await _storage.read(key: keyEmail);
        final password = await _storage.read(key: keyPassword);

        if (email != null && email.isNotEmpty) {
          return SavedCredentials(
            email: email,
            password: password ?? '',
            rememberMe: true,
          );
        }
      }
    } catch (_) {}
    return _memoryCache;
  }

  /// Clears stored credentials when user unchecks Remember Me or signs out
  static Future<void> clearCredentials() async {
    _memoryCache = null;
    if (isTestMode) return;
    try {
      await _storage.delete(key: keyEmail);
      await _storage.delete(key: keyPassword);
      await _storage.delete(key: keyRememberMe);
    } catch (_) {}
  }
}
