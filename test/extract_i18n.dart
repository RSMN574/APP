import 'dart:convert';
import 'dart:io';

void main() async {
  final arb = <String, String>{};
  int counter = 1;

  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  // ✅ 改进正则：不跨行匹配，且引号内排除换行符
  final chineseRegex = RegExp(r'''["']([^"'\n\r]*[\u4e00-\u9fff]+[^"'\n\r]*)["']''');

  for (final file in files) {
    final content = await file.readAsString();

    for (final match in chineseRegex.allMatches(content)) {
      String text = match.group(1)?.trim() ?? '';
      if (text.isEmpty) continue;

      // ✅ 新增：计算中文字符占比，过滤掉噪音
      final chineseChars = text.replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '');
      if (chineseChars.isEmpty) continue;

      // 如果中文字符占比低于 50%，则跳过（可调整阈值）
      final ratio = chineseChars.length / text.length;
      if (ratio < 0.5) continue;

      // 去除多余空白和换行
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (arb.containsValue(text)) continue;
      arb['text_$counter'] = text;
      counter++;
    }
  }

  final output = {
    "@@locale": "zh",
    ...arb,
  };

  final outFile = File('lib/l10n/app_zh.arb');
  await outFile.create(recursive: true);
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  print('完成，共找到 ${arb.length} 個中文字串');
}