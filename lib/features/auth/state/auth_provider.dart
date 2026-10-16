import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/auth_failure.dart';
import '../data/models/auth_user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? FirebaseAuthRepository() {
    _authSubscription = _repository.authStateChanges.listen(
      (user) {
        _currentUser = user;
        _isInitialized = true;
        _notifyListeners();
      },
      onError: (Object _) {
        _error = AuthFailureCode.unavailable;
        _isInitialized = true;
        _notifyListeners();
      },
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthUserModel?> _authSubscription;

  AuthUserModel? _currentUser;
  AuthFailureCode? _error;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  bool _passwordResetSent = false;
  bool _disposed = false;

  AuthUserModel? get currentUser => _currentUser;
  AuthFailureCode? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoading => !_isInitialized || _isSubmitting;
  bool get isSignedIn => _currentUser != null;
  bool get passwordResetSent => _passwordResetSent;

  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.signIn(
          email: email.trim(),
          password: password,
        ));
  }

  Future<bool> register({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.register(
          email: email.trim(),
          password: password,
        ));
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    final succeeded = await _run<void>(
      () => _repository.sendPasswordResetEmail(email.trim()),
    );
    _passwordResetSent = succeeded;
    _notifyListeners();
    return succeeded;
  }

  Future<bool> signOut() => _run(_repository.signOut);

  Future<bool> updateProfile({String? displayName, Uint8List? avatarBytes}) {
    return _run(() async {
      _currentUser = await _repository.updateProfile(
        displayName: displayName,
        avatarBytes: avatarBytes,
      );
    });
  }

  Future<bool> deleteAccount({String? password}) {
    return _run(() => _repository.deleteAccount(password: password));
  }

  Future<bool> _run<T>(Future<T> Function() action) async {
    if (_disposed || _isSubmitting) return false;
    _error = null;
    _passwordResetSent = false;
    _isSubmitting = true;
    _notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      _error = failure.code;
      return false;
    } catch (_) {
      _error = AuthFailureCode.unknown;
      return false;
    } finally {
      _isSubmitting = false;
      _notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _passwordResetSent = false;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
