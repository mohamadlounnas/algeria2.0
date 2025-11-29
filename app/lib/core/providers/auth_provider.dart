import 'package:flutter/material.dart';
import '../../shared/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}

class AuthProvider extends InheritedWidget {
  final User? user;
  final String? token;
  final bool isLoading;
  final VoidCallback? login;
  final VoidCallback? logout;
  final Function(String email, String password)? signIn;
  final Function(String email, String password, String name)? signUp;

  const AuthProvider({
    super.key,
    required super.child,
    this.user,
    this.token,
    this.isLoading = false,
    this.login,
    this.logout,
    this.signIn,
    this.signUp,
  });

  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return user != oldWidget.user ||
        token != oldWidget.token ||
        isLoading != oldWidget.isLoading;
  }
}

class AuthProviderState extends StatefulWidget {
  final Widget child;

  const AuthProviderState({super.key, required this.child});

  @override
  State<AuthProviderState> createState() => _AuthProviderStateState();
}

class _AuthProviderStateState extends State<AuthProviderState> {
  User? _user;
  String? _token;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    await _apiService.loadToken();
    final token = _apiService.token;
    if (token != null) {
      _apiService.setToken(token);
      // Try to get current user
      try {
        final response = await _apiService.get('${ApiConstants.auth}/me');
        setState(() {
          _user = User.fromJson(response as Map<String, dynamic>);
          _token = token;
        });
      } catch (e) {
        // Token invalid, clear it
        await _apiService.clearToken();
        setState(() {
          _token = null;
        });
      }
    }
  }

  Future<void> _signIn(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        '${ApiConstants.auth}/sign-in',
        {
          'email': email,
          'password': password,
        },
      );
      
      if (response['token'] != null && response['user'] != null) {
        final token = response['token'] as String;
        _apiService.setToken(token);
        setState(() {
          _token = token;
          _user = User.fromJson(response['user'] as Map<String, dynamic>);
        });
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp(String email, String password, String name) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        '${ApiConstants.auth}/sign-up',
        {
          'email': email,
          'password': password,
          'name': name,
        },
      );
      
      if (response['token'] != null && response['user'] != null) {
        final token = response['token'] as String;
        _apiService.setToken(token);
        setState(() {
          _token = token;
          _user = User.fromJson(response['user'] as Map<String, dynamic>);
        });
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _apiService.clearToken();
    setState(() {
      _user = null;
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      user: _user,
      token: _token,
      isLoading: _isLoading,
      signIn: _signIn,
      signUp: _signUp,
      logout: _logout,
      child: widget.child,
    );
  }
}

