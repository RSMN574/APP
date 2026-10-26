// lib/database/bootstrap_service.dart
import 'dart:convert';

import 'package:com.rsmn574.app/database/sql/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/bus/model/bus_route_model.dart';
import 'meta_db.dart';

class BootstrapService {
  BootstrapService._();
  static final BootstrapService instance = BootstrapService._();

  static const _baseUrl = 'http://hidden.rsmn574.com:3920';
  static const _etagKey = 'bootstrap_etag';
  static const _timeout = Duration(seconds: 20);

  /// DB 內容變動時 +1；UI 監聽此值即可在 bootstrap 完成後重查。
  final ValueNotifier<int> dbVersion = ValueNotifier<int>(0);

  /// App 啟動時呼叫；city 預設 all（全量）。
  Future<void> ensureLoaded({String city = 'all'}) async {
    print('[bootstrap] 開始 city=$city');
    try {
      final etag = await MetaDb.instance.get(_etagKey);
      print('[bootstrap] etag=$etag');

      final uri = Uri.parse('$_baseUrl/bootstrap')
          .replace(queryParameters: {'city': city});
      print('[bootstrap] url=$uri');

      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
      }).timeout(_timeout);

      print('[bootstrap] status=${resp.statusCode}');
      if (resp.statusCode == 304) {
        print('[bootstrap] 304 跳過');
        return;
      }
      if (resp.statusCode != 200) {
        throw Exception('status ${resp.statusCode}');
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final rawList = (data['busList'] as List?) ?? const [];
      print('[bootstrap] raw=${rawList.length}');

      final busList = <BusRoute>[];
      for (final e in rawList) {
        if (e is! Map) continue;
        try {
          busList.add(BusRoute.fromJson(Map<String, dynamic>.from(e)));
        } catch (err) {
          print('[bootstrap] parse fail: $err');
        }
      }
      print('[bootstrap] parsed=${busList.length}');

      await BusRouteDb.instance.replaceCity(city, busList);
      print('[bootstrap] replaceCity done');

      final newEtag = resp.headers['etag'];
      if (newEtag != null && newEtag.isNotEmpty) {
        await MetaDb.instance.set(_etagKey, newEtag);
        print('[bootstrap] etag saved=$newEtag');
      }

      dbVersion.value++;
      print('[bootstrap] dbVersion=${dbVersion.value}');
    } catch (e, st) {
      print('[bootstrap] 失敗: $e');
      print('[bootstrap] stack: $st');
    }
  }
  /// 手動強制同步（下拉刷新用）
  Future<void> sync({String city = 'all'}) async {
    await MetaDb.instance.set(_etagKey, ''); // 讓 If-None-Match 失效
    await ensureLoaded(city: city);
  }
}