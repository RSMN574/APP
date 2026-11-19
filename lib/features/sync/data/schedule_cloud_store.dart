import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// 行程雲端儲存位置（`users/{uid}/schedules`）。
///
/// 由 sync 模組自己持有，避免 sync 反向 import auth 的資料來源而形成
/// `auth ↔ sync` 循環依賴（QA 架構審查 B3）。auth 刪除帳號時也引用此處的路徑。
class ScheduleCloudStore {
  ScheduleCloudStore({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  static const usersCollection = 'users';
  static const schedulesCollection = 'schedules';

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> schedules(String uid) => _firestore
      .collection(usersCollection)
      .doc(uid)
      .collection(schedulesCollection);

  /// Firestore 文件 ID 不可含 `/`，以 base64url 編碼行程鍵值。
  static String documentId(String key) =>
      base64Url.encode(utf8.encode(key)).replaceAll('=', '');
}
