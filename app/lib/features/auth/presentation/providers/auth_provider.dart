import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/di/di_provider.dart';
import '../../../../core/di/dio_client.dart';

class AuthProvider extends InheritedWidget {
  final User? user;
  final String? token;
  final bool isLoading;
  final bool isInitialized;
  final Future<void> Function(String email, String password)? signIn;
  final Future<void> Function(String email, String password, String name)? signUp;
  final Future<void> Function()? signOut;

  const AuthProvider({
    super.key,
    required super.child,
    this.user,
    this.token,
    this.isLoading = false,
    this.isInitialized = false,
    this.signIn,
    this.signUp,
    this.signOut,
  });

  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return user != oldWidget.user ||
        token != oldWidget.token ||
        isLoading != oldWidget.isLoading ||
        isInitialized != oldWidget.isInitialized;
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
  bool _hasInitialized = false;
  AuthRepository? _authRepository;
  DioClient? _dioClient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get DioClient from DI (only once)
    if (_dioClient == null) {
      _dioClient = DiProvider.getDioClient(context);
      _authRepository = AuthRepositoryImpl(dio: _dioClient!.dio);
      _loadSession();
    }
  }

  Future<void> _loadSession() async {
    if (_dioClient == null || _authRepository == null) {
      setState(() => _hasInitialized = true);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    
    debugPrint('🔄 Loading session - Token from storage: ${savedToken != null ? savedToken.substring(0, 20) + '...' : 'NULL'}');
    
    if (savedToken != null && savedToken.isNotEmpty) {
      _dioClient!.setToken(savedToken);
      debugPrint('✅ Token set in DioClient');
      try {
        final user = await _authRepository!.getCurrentUser();
        setState(() {
          _user = user;
          _token = savedToken;
        });
        debugPrint('✅ Session loaded: User ${user.email}');
      } catch (e) {
        debugPrint('❌ Failed to load session: $e');
        await _clearToken();
        _dioClient!.setToken(null);
      }
    } else {
      debugPrint('ℹ️ No saved session found');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasInitialized = true;
      });
    }
  }

  Future<void> _signIn(String email, String password) async {
    if (_authRepository == null || _dioClient == null) return;
    
    setState(() => _isLoading = true);
    try {
      final result = await _authRepository!.signIn(email, password);
      debugPrint('✅ Sign in successful, token received: ${result.token.substring(0, 20)}...');
      await _saveToken(result.token);
      _dioClient!.setToken(result.token);
      setState(() {
        _user = result.user;
        _token = result.token;
      });
      debugPrint('✅ Token set in DioClient, user: ${result.user.email}');
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp(String email, String password, String name) async {
    if (_authRepository == null || _dioClient == null) return;
    
    setState(() => _isLoading = true);
    try {
      final result = await _authRepository!.signUp(email, password, name);
      debugPrint('✅ Sign up successful, token received: ${result.token.substring(0, 20)}...');
      await _saveToken(result.token);
      _dioClient!.setToken(result.token);
      setState(() {
        _user = result.user;
        _token = result.token;
      });
      debugPrint('✅ Token set in DioClient, user: ${result.user.email}');
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _clearToken();
    _dioClient?.setToken(null);
    setState(() {
      _user = null;
      _token = null;
    });
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      user: _user,
      token: _token,
      isLoading: _isLoading,
      isInitialized: _hasInitialized,
      signIn: _signIn,
      signUp: _signUp,
      signOut: _signOut,
      child: widget.child,
    );
  }
}

