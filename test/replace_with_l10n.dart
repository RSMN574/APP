import 'dart:io';
import 'dart:convert';

void main() async {
  // 建立中文字串到 key 的對應
  final arbFile = File('lib/l10n/app_zh.arb');
  if (!await arbFile.exists()) {
    print('請先執行 flutter gen-l10n');
    return;
  }

  final arbContent = await arbFile.readAsString();
  final Map<String, dynamic> arbMap = jsonDecode(arbContent);

  final Map<String, String> textToKey = {};
  arbMap.forEach((key, value) {
    if (key != '@@locale' && value is String) {
      textToKey[value] = key;
    }
  });

  // 掃描並替換
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('l10n'));

  for (final file in files) {
    var content = await file.readAsString();
    var newContent = content;

    // 更精確的匹配：只匹配字串字面量，不匹配註釋
    final regex = RegExp(
      r'''(['"])([^"'\n\r]*[\u4e00-\u9fff]+[^"'\n\r]*)\1''',
    );

    for (final match in regex.allMatches(content)) {
      final fullMatch = match.group(0)!;
      final text = match.group(2)!.trim();

      if (textToKey.containsKey(text)) {
        final key = textToKey[text]!;

        // 檢查是否在註釋中
        final beforeText = content.substring(0, match.start);
        final lastLineStart = beforeText.lastIndexOf('\n');
        final linePrefix = lastLineStart != -1
            ? beforeText.substring(lastLineStart + 1)
            : beforeText;

        // 跳過註釋中的字串
        if (linePrefix.trim().startsWith('//') ||
            linePrefix.trim().startsWith('/*') ||
            linePrefix.trim().startsWith('*')) {
          continue;
        }

        // 檢查是否已在 AppLocalizations 中
        final contextCheck = content.substring(
          match.start - 100 > 0 ? match.start - 100 : 0,
          match.start,
        );
        if (contextCheck.contains('AppLocalizations')) continue;

        // 替換
        newContent = newContent.replaceFirst(
          fullMatch,
          'AppLocalizations.of(context)!.$key',
        );

        print('✓ 替換: "$text" -> $key (${file.path})');
      }
    }

    if (content != newContent) {
      await file.writeAsString(newContent);
      print('📝 已更新: ${file.path}');
    }
  }
}