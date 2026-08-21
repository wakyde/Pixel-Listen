import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _tryAutoRefresh().then((refreshed) {
        if (refreshed) {
          handler.next(err);
        } else {
          handler.next(err);
        }
      });
    } else {
      handler.next(err);
    }
  }

  Future<bool> _tryAutoRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8000',
        connectTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.post('/api/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      final data = response.data as Map<String, dynamic>;
      await prefs.setString('jwt_token', data['access_token'] as String);
      await prefs.setString('refresh_token', data['refresh_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }
}