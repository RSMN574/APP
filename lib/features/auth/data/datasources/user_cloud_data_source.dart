import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/auth_user_model.dart';

class UserCloudDataSource {
  UserCloudDataSource({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> schedules(String uid) =>
      _userDoc(uid).collection('schedules');

  Reference _avatarRef(String uid) => _storage.ref('avatars/$uid.jpg');

  Future<void> upsertProfile(AuthUserModel user) {
    return _userDoc(user.uid).set({
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'providers': user.providerIds,
      'createdAt':
          user.createdAt == null ? null : Timestamp.fromDate(user.createdAt!),
      'lastSignInAt': user.lastSignInAt == null
          ? null
          : Timestamp.fromDate(user.lastSignInAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _avatarRef(uid);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteAllUserData(String uid) async {
    final snapshot = await schedules(uid).get();
    for (var i = 0; i < snapshot.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _userDoc(uid).delete();
    try {
      await _avatarRef(uid).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  static String documentId(String key) =>
      base64Url.encode(utf8.encode(key)).replaceAll('=', '');
}
