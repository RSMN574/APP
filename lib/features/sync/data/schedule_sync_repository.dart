import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../database/sql/schedule.dart';
import '../../auth/data/datasources/user_cloud_data_source.dart';

class ScheduleSyncResult {
  const ScheduleSyncResult({required this.uploaded, required this.downloaded});

  final int uploaded;
  final int downloaded;
}

class ScheduleSyncRepository {
  ScheduleSyncRepository({
    UserCloudDataSource? cloud,
    ScheduleService? scheduleService,
  })  : _cloud = cloud ?? UserCloudDataSource(),
        _schedules = scheduleService ?? ScheduleService.instance;

  final UserCloudDataSource _cloud;
  final ScheduleService _schedules;

  static String _key(Map<String, dynamic> m) => [
        m['type'],
        m['Route'],
        m['StartingStopName'],
        m['FinalStopName'],
        m['UserStartingStopName'],
        m['UserDestinationStopName'],
        m['city'],
        m['time'],
      ].map((e) => e ?? '').join('|');

  /// Merges local and cloud schedules by content (union), so itineraries
  /// created on any device appear on all signed-in devices.
  Future<ScheduleSyncResult> sync(String uid) async {
    final collection = _cloud.schedules(uid);
    final local = await _schedules.getSchedules();
    final remoteSnapshot = await collection.get();

    final localKeys = local.map(_key).toSet();
    final remoteKeys = <String>{};
    var downloaded = 0;
    var uploaded = 0;

    for (final doc in remoteSnapshot.docs) {
      final data = doc.data()..remove('syncedAt');
      final key = _key(data);
      remoteKeys.add(key);
      if (localKeys.contains(key)) continue;
      final result = await _schedules.addSchedule(ScheduleModel.fromMap(data));
      if (result == 100) downloaded++;
    }

    var batch = FirebaseFirestore.instance.batch();
    var pending = 0;
    for (final item in local) {
      final key = _key(item);
      if (remoteKeys.contains(key)) continue;
      final data = Map<String, dynamic>.of(item)..remove('id');
      batch.set(collection.doc(UserCloudDataSource.documentId(key)), {
        ...data,
        'syncedAt': FieldValue.serverTimestamp(),
      });
      uploaded++;
      if (++pending == 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();

    return ScheduleSyncResult(uploaded: uploaded, downloaded: downloaded);
  }
}
