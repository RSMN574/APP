class AuthUserModel {
  const AuthUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.emailVerified,
    this.createdAt,
    this.lastSignInAt,
    this.providerIds = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final List<String> providerIds;

  bool get hasPasswordProvider => providerIds.contains('password');
}
