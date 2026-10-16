import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flight_mileage_record.dart';

class FlightMileageRepository {
  FlightMileageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('flight_records');

  Stream<List<FlightMileageRecord>> stream(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlightMileageRecord.fromMap(doc.data(), overrideId: doc.id))
            .toList());
  }

  Future<List<FlightMileageRecord>> load(String uid) async {
    final snapshot = await _collection(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => FlightMileageRecord.fromMap(doc.data(), overrideId: doc.id))
        .toList();
  }

  Future<void> upsert(String uid, FlightMileageRecord record) async {
    await _collection(uid).doc(record.id).set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String uid, String id) async {
    await _collection(uid).doc(id).delete();
  }

  Future<double> totalDistance(String uid) async {
    final records = await load(uid);
    return records.fold<double>(0, (sum, item) => sum + item.distanceKm);
  }
}
