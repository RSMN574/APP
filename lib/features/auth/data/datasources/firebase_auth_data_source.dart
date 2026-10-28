import 'package:firebase_auth/firebase_auth.dart';

import '../../model/auth_failure.dart';
import '../../model/auth_user_model.dart';


class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<AuthUserModel?> get authStateChanges =>
      _firebaseAuth.userChanges().map(_mapUser);

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
      return _mapUser(user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<AuthUserModel> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
      return _mapUser(user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  AuthUserModel? get currentUser => _mapUser(_firebaseAuth.currentUser);

  Future<AuthUserModel> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
    try {
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoURL != null) await user.updatePhotoURL(photoURL);
      await user.reload();
      return _mapUser(_firebaseAuth.currentUser)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<void> reauthenticate(String? password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
    final email = user.email;
    final isPassword =
        user.providerData.any((info) => info.providerId == 'password');
    if (!isPassword || email == null || password == null || password.isEmpty) {
      return;
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<void> deleteUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  AuthUserModel? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
      providerIds: user.providerData.map((info) => info.providerId).toList(),
    );
  }

  AuthFailureCode _mapFirebaseError(String code) {
    return switch (code) {
      'invalid-email' => AuthFailureCode.invalidEmail,
      'user-disabled' => AuthFailureCode.userDisabled,
      'user-not-found' => AuthFailureCode.userNotFound,
      'wrong-password' || 'invalid-credential' => AuthFailureCode.wrongPassword,
      'email-already-in-use' => AuthFailureCode.emailAlreadyInUse,
      'weak-password' => AuthFailureCode.weakPassword,
      'operation-not-allowed' => AuthFailureCode.operationNotAllowed,
      'too-many-requests' => AuthFailureCode.tooManyRequests,
      'network-request-failed' => AuthFailureCode.networkRequestFailed,
      'requires-recent-login' => AuthFailureCode.requiresRecentLogin,
      _ => AuthFailureCode.unknown,
    };
  }
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }

  Future<AuthUserModel> reloadUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }

    try {
      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser == null) {
        throw const AuthFailure(AuthFailureCode.unknown);
      }

      return _mapUser(refreshedUser)!;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseError(error.code));
    }
  }
}
