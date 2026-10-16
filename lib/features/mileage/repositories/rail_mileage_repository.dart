import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/rail_mileage_record.dart';

class RailMileageRepository {
  RailMileageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('rail_records');

  Stream<List<RailMileageRecord>> stream(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RailMileageRecord.fromMap(doc.data(), overrideId: doc.id))
            .toList());
  }

  Future<List<RailMileageRecord>> load(String uid) async {
    final snapshot = await _collection(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => RailMileageRecord.fromMap(doc.data(), overrideId: doc.id))
        .toList();
  }

  Future<void> upsert(String uid, RailMileageRecord record) async {
    final ref = _collection(uid).doc(record.id);
    await ref.set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String uid, String id) async {
    await _collection(uid).doc(id).delete();
  }

  Future<double> totalDistance(String uid) async {
    final records = await load(uid);
    return records.fold<double>(0, (sum, record) => sum + record.distanceKm);
  }
}
