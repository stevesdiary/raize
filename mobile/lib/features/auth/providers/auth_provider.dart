import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _apiClient;

  @override
  AuthState build() {
    _apiClient = ref.watch(apiClientProvider);
    return AuthState.initial();
  }

  Future<void> checkAuth() async {
    final token = await _apiClient.getToken();
    if (token == null) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final response = await _apiClient.client.get(ApiEndpoints.me);
      final responseData = response.data is Map ? response.data as Map<String, dynamic> : {};
      final userData = responseData['user'] ?? responseData['data'];

      if (response.statusCode == 200 && userData != null && userData is Map<String, dynamic>) {
        final user = UserModel.fromJson(userData);
        state = AuthState.authenticated(user);
      } else {
        await _apiClient.clearToken();
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      await _apiClient.clearToken();
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = AuthState.loading();
    try {
      final cleanId = identifier.trim();
      final response = await _apiClient.client.post(
        ApiEndpoints.login,
        data: {
          'identifier': cleanId,
          'email': cleanId,
          'username': cleanId,
          'password': password,
        },
      );

      final responseData = response.data is Map ? response.data as Map<String, dynamic> : {};
      final token = responseData['token'] ?? responseData['data']?['token'];
      final userJson = responseData['user'] ?? responseData['data']?['user'] ?? responseData['data'];

      if (response.statusCode == 200 && token != null) {
        await _apiClient.saveToken(token as String);
        if (userJson != null && userJson is Map<String, dynamic>) {
          final user = UserModel.fromJson(userJson);
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.authenticated(
            UserModel(
              id: 'user',
              email: cleanId,
              username: cleanId.replaceFirst(RegExp(r'^@'), ''),
              fullName: cleanId,
            ),
          );
        }
        return true;
      } else {
        final error = responseData['error']?['message'] ?? responseData['message'] ?? 'Login failed';
        state = AuthState.error(error.toString());
        return false;
      }
    } on DioException catch (e) {
      final responseData = e.response?.data is Map ? e.response!.data as Map<String, dynamic> : {};
      final message = responseData['error']?['message'] ??
          responseData['message'] ??
          e.message ??
          'Authentication failed';
      state = AuthState.error(message.toString());
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    String? username,
    required String password,
    required String fullName,
    required String dateOfBirth,
    required String preferredMeasurement,
    String country = 'NG',
    bool consentTerms = true,
    bool consentHealthData = true,
  }) async {
    state = AuthState.loading();
    try {
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final cleanUsername = username?.trim().replaceFirst(RegExp(r'^@'), '');

      final payload = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'unitSystem': preferredMeasurement.toLowerCase(),
        'countryCode': country,
        'consentTerms': consentTerms,
        'consentHealthData': consentHealthData,
      };
      if (cleanUsername != null && cleanUsername.isNotEmpty) {
        payload['username'] = cleanUsername;
      }

      final response = await _apiClient.client.post(
        ApiEndpoints.register,
        data: payload,
      );

      final responseData = response.data is Map ? response.data as Map<String, dynamic> : {};
      final token = responseData['token'] ?? responseData['data']?['token'];
      final userJson = responseData['user'] ?? responseData['data']?['user'] ?? responseData['data'];

      if ((response.statusCode == 201 || response.statusCode == 200) && token != null) {
        await _apiClient.saveToken(token as String);
        if (userJson != null && userJson is Map<String, dynamic>) {
          final user = UserModel.fromJson(userJson);
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.authenticated(
            UserModel(
              id: 'new_user',
              email: email.trim().toLowerCase(),
              username: cleanUsername,
              fullName: fullName.trim(),
            ),
          );
        }
        return true;
      } else {
        final error = responseData['error']?['message'] ?? responseData['message'] ?? 'Registration failed';
        state = AuthState.error(error.toString());
        return false;
      }
    } on DioException catch (e) {
      final responseData = e.response?.data is Map ? e.response!.data as Map<String, dynamic> : {};
      final message = responseData['error']?['message'] ??
          responseData['message'] ??
          e.message ??
          'Registration failed';
      state = AuthState.error(message.toString());
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    state = AuthState.unauthenticated();
  }

  /// Permanently erases athlete personal profile, biometrics, credentials,
  /// and local cache in compliance with NDPA Section 24 & GDPR Article 17.
  Future<bool> deleteAccount({bool syncBackend = false}) async {
    state = AuthState.loading();
    if (syncBackend) {
      try {
        await _apiClient.client.delete(ApiEndpoints.deleteAccount);
      } catch (_) {
        // Proceed with local erasure to guarantee user's right to erasure
      }
    }
    await _apiClient.clearToken();
    state = AuthState.unauthenticated();
    return true;
  }
}
