import 'dart:typed_data';

import '../models/auth_user_model.dart';

abstract interface class AuthRepository {
  Stream<AuthUserModel?> get authStateChanges;

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });

  Future<AuthUserModel> register({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<AuthUserModel> updateProfile({
    String? displayName,
    Uint8List? avatarBytes,
  });

  Future<void> deleteAccount({String? password});
}
