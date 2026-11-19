import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:com.rsmn574.app/const/regular_class.dart';

void main() {
  group('AppProvider theme mode', () {
    test('loads the system mode by default', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = await AppProvider.load();

      expect(provider.themeMode, ThemeMode.system);
    });

    test('persists all supported theme modes', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = await AppProvider.load();

      for (final mode in ThemeMode.values) {
        await provider.setThemeMode(mode);
        final reloaded = await AppProvider.load();
        expect(reloaded.themeMode, mode);
      }
    });
  });
}
