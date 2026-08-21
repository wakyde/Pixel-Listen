import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'models.dart';

final currentUserProvider = Provider<User?>((ref) {
  return AuthService.currentUser;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});