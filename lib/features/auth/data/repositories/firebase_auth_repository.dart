import 'package:flutter/foundation.dart';

import '../../model/auth_failure.dart';
import '../../model/auth_user_model.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/user_cloud_data_source.dart';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuthDataSource? dataSource,
    UserCloudDataSource? cloudDataSource,
  })  : _dataSource = dataSource ?? FirebaseAuthDataSource(),
        _cloud = cloudDataSource ?? UserCloudDataSource();

  final FirebaseAuthDataSource _dataSource;
  final UserCloudDataSource _cloud;

  @override
  Stream<AuthUserModel?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.signIn(email: email, password: password);
    await _syncProfile(user);
    return user;
  }
  @override
  Future<void> sendEmailVerification() {
    return _dataSource.sendEmailVerification();
  }

  @override
  Future<AuthUserModel> reloadUser() {
    return _dataSource.reloadUser();
  }
  @override
  Future<AuthUserModel> register({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.register(email: email, password: password);
    await _syncProfile(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<AuthUserModel> updateProfile({
    String? displayName,
    Uint8List? avatarBytes,
  }) async {
    final current = _dataSource.currentUser;
    if (current == null) throw const AuthFailure(AuthFailureCode.unknown);
    String? photoURL;
    if (avatarBytes != null) {
      try {
        photoURL = await _cloud.uploadAvatar(current.uid, avatarBytes);
      } catch (error) {
        debugPrint('Avatar upload failed: $error');
        throw const AuthFailure(AuthFailureCode.storageFailed);
      }
    }
    final user = await _dataSource.updateProfile(
      displayName: displayName?.trim(),
      photoURL: photoURL,
    );
    await _syncProfile(user);
    return user;
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final current = _dataSource.currentUser;
    if (current == null) return;
    await _dataSource.reauthenticate(password);
    try {
      await _cloud.deleteAllUserData(current.uid);
    } catch (error) {
      debugPrint('Cloud data deletion failed: $error');
      throw const AuthFailure(AuthFailureCode.storageFailed);
    }
    await _dataSource.deleteUser();
  }

  Future<void> _syncProfile(AuthUserModel user) async {
    try {
      await _cloud.upsertProfile(user);
    } catch (error) {
      debugPrint('Profile sync failed: $error');
    }
  }
}
