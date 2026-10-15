import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/features/metro/data/metro_repository.dart';

void main() async {
  // 建立輸出資料夾
  final dir = Directory('output_json');
  if (!dir.existsSync()) dir.createSync();

  // 要輸出的城市清單
  final Map<String, CityMetroData> cities = {
    'taipei': MetroRepository.taipei,
    'kaohsiung': MetroRepository.kaohsiung,
    'taichung': MetroRepository.taichung,
  };

  // 逐一寫入檔案
  for (final entry in cities.entries) {
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(entry.value.toJson());
    final file = File('${dir.path}/${entry.key}.json');
    await file.writeAsString(jsonString, encoding: utf8);
    print('✅ 已產生：${file.path}');
  }
}
