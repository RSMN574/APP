import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 解析 `Estimates` 欄位。
/// 原 API 有兩種格式：標準 JSON，或 Dart `Map.toString()` 產生的非標準字串。
class BusEstimatesParser {
  const BusEstimatesParser._();

  static List<Map<String, dynamic>> parse(String? raw) {
    if (raw == null) return const [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == '[]') {
      return const [];
    }

    // 1) 先試標準 JSON
    final direct = _tryDecode(trimmed);
    if (direct != null) return direct;

    // 2) 再用原本程式的正則修復
    try {
      final repaired = trimmed
          .replaceAllMapped(RegExp(r'(\w+):'), (m) => '"${m[1]}":')
          .replaceAllMapped(RegExp(r'(\w+-\w+)'), (m) => '"${m[0]}"');
      final fixed = _tryDecode(repaired);
      if (fixed != null) return fixed;
    } catch (e) {
      debugPrint('BusEstimatesParser: repair failed: $e');
    }

    debugPrint('BusEstimatesParser: unable to parse: $raw');
    return const [];
  }

  static List<Map<String, dynamic>>? _tryDecode(String text) {
    try {
      final decoded = json.decode(text);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return null;
  }
}