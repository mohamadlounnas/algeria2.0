import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _client = http.Client();
  
  // Expose token for AuthProvider
  String? get token => _token;

  // Bearer token authentication
  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _persistToken(token);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    String filePath,
    Map<String, String> fields,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );

    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // Persist token to SharedPreferences
  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Load token from SharedPreferences
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      final decoded = jsonDecode(response.body);
      // Handle both array and object responses
      if (decoded is List) {
        return {'data': decoded};
      }
      return decoded as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      String errorMessage = 'Request failed: ${response.statusCode}';
      try {
        final errorJson = jsonDecode(errorBody);
        errorMessage = errorJson['message'] ?? errorJson['error'] ?? errorMessage;
      } catch (_) {
        if (errorBody.isNotEmpty) {
          errorMessage = errorBody;
        }
      }
      throw Exception(errorMessage);
    }
  }
}

