import 'dart:async';

import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'auth_interceptor.dart';
import 'models.dart';

class AuthService {
  AuthService._();

  static final StreamController<User?> _userController =
      StreamController<User?>.broadcast(
    onListen: () {
      _userController.add(_currentUser);
    },
  );
  static Stream<User?> get userStream => _userController.stream;

  static late final Dio _dio;

  static Dio get dio => _dio;

  static User? _currentUser;
  static User? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static Future<void> initialize({
    bool mockMode = false,
    String baseUrl = 'http://localhost:8000',
  }) async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(AuthInterceptor());

    if (mockMode) {
      _currentUser = User(
        id: 'mock-user-001',
        username: 'Demo User',
        email: 'demo@example.com',
        createdAt: _zeroTime,
      );
      _userController.add(_currentUser);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      try {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.get('/api/auth/me');
        if (response.statusCode == 200) {
          _currentUser = User.fromJson(response.data as Map<String, dynamic>);
        }
      } catch (_) {
        await _tryRefreshToken();
      }
    }
  }

  static Future<AuthTokens> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _validatePassword(password);

    final response = await _dio.post('/api/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });

    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(tokens);
    await _fetchCurrentUser();
    return tokens;
  }

  static Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(tokens);
    await _fetchCurrentUser();
    return tokens;
  }

  static Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
    _dio.options.headers.remove('Authorization');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  static Future<bool> _tryRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshKey);
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post('/api/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(tokens);
      await _fetchCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveTokens(AuthTokens tokens) async {
    _dio.options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, tokens.accessToken);
    await prefs.setString(_refreshKey, tokens.refreshToken);
  }

  static Future<void> _fetchCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    _currentUser = User.fromJson(response.data as Map<String, dynamic>);
    _userController.add(_currentUser);
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw ArgumentError(
        'Password must be at least 8 characters',
      );
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw ArgumentError(
        'Password must contain at least one uppercase letter',
      );
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw ArgumentError(
        'Password must contain at least one lowercase letter',
      );
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw ArgumentError(
        'Password must contain at least one digit',
      );
    }
  }

  static String get _tokenKey => 'jwt_token';
  static String get _refreshKey => 'refresh_token';
  static final DateTime _zeroTime = DateTime(1970);
}