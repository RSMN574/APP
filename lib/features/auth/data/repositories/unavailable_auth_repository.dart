import 'dart:typed_data';

import '../../model/auth_failure.dart';
import '../../model/auth_user_model.dart';

import 'auth_repository.dart';

class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  @override
  Stream<AuthUserModel?> get authStateChanges => Stream.value(null);

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<void> sendPasswordResetEmail(String email) => _unavailable();
  @override
  Future<void> sendEmailVerification() => _unavailable();

  @override
  Future<AuthUserModel> reloadUser() => _unavailable();

  @override
  Future<void> signOut() => _unavailable();

  @override
  Future<AuthUserModel> updateProfile({
    String? displayName,
    Uint8List? avatarBytes,
  }) =>
      _unavailable();

  @override
  Future<void> deleteAccount({String? password}) => _unavailable();

  Future<T> _unavailable<T>() =>
      Future<T>.error(const AuthFailure(AuthFailureCode.unavailable));
}
