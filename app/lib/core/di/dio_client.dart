import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio _dio;
  String? _token;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor for Authorization header
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            final authHeader = 'Bearer $_token';
            options.headers['Authorization'] = authHeader;
            if (kDebugMode) {
              debugPrint('🔐 Adding Authorization header: Bearer ${_token!.substring(0, 20)}...');
              debugPrint('🔐 Full Authorization header: $authHeader');
              debugPrint('🔐 Request URL: ${options.baseUrl}${options.path}');
              debugPrint('🔐 Request headers: ${options.headers}');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ No token available for request to: ${options.path}');
              debugPrint('⚠️ Token value: $_token');
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('❌ Request error: ${error.response?.statusCode} - ${error.message}');
            if (error.response != null) {
              debugPrint('Response data: ${error.response?.data}');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String? token) {
    _token = token;
    // Also update base options headers
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
    if (kDebugMode) {
      if (token != null) {
        debugPrint('✅ Token set: ${token.substring(0, 20)}...');
      } else {
        debugPrint('🗑️ Token cleared');
      }
    }
  }

  /// Load token from SharedPreferences and set it
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setToken(savedToken);
      if (kDebugMode) {
        debugPrint('✅ Token loaded from SharedPreferences');
      }
    } else {
      if (kDebugMode) {
        debugPrint('ℹ️ No token found in SharedPreferences');
      }
    }
  }

  String? get token => _token;

  Dio get dio => _dio;
}
