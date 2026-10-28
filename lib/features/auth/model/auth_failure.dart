enum AuthFailureCode {
  invalidEmail,
  userDisabled,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  operationNotAllowed,
  tooManyRequests,
  networkRequestFailed,
  requiresRecentLogin,
  storageFailed,
  unavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
