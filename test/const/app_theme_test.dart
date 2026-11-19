import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/widget/app_state_views.dart';

void main() {
  group('AppThemes design baseline', () {
    test('light theme uses the brand palette', () {
      final scheme = AppThemes.lightTheme.colorScheme;
      expect(scheme.primary, const Color(0xFF1A73E8));
      expect(AppThemes.lightTheme.scaffoldBackgroundColor,
          const Color(0xFFF8FAFD));
      expect(scheme.surfaceContainer, const Color(0xFFEEF3FB));
    });

    test('dark theme uses the lighter primary with readable foreground', () {
      final scheme = AppThemes.darkTheme.colorScheme;
      expect(scheme.primary, const Color(0xFF64B5F6));
      // 深色 primary 上的文字必須是深色，白字對比不足。
      expect(scheme.onPrimary.computeLuminance(), lessThan(0.1));
    });

    test('AppColors is registered as a ThemeExtension for both modes', () {
      expect(AppThemes.lightTheme.extension<AppColors>(), AppColors.light);
      expect(AppThemes.darkTheme.extension<AppColors>(), AppColors.dark);
    });

    test('cards use radius 20 and buttons radius 12', () {
      final card =
          AppThemes.lightTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(20));
      final button = AppThemes.lightTheme.filledButtonTheme.style!.shape!
          .resolve({}) as RoundedRectangleBorder;
      expect(button.borderRadius, BorderRadius.circular(12));
    });
  });

  group('shared state views', () {
    Future<void> pump(WidgetTester tester, Widget child,
        {ThemeMode mode = ThemeMode.light, double textScale = 1}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: mode,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: widget!,
          ),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('error view shows localized retry and calls back',
        (tester) async {
      var retried = 0;
      await pump(
        tester,
        AppErrorView(message: '載入失敗', onRetry: () => retried++),
      );
      expect(find.text('載入失敗'), findsOneWidget);
      await tester.tap(find.text('重試'));
      expect(retried, 1);
    });

    testWidgets('empty view renders in dark mode at 2x text without overflow',
        (tester) async {
      await pump(
        tester,
        const AppEmptyView(title: '暫無公告', message: '目前沒有資料'),
        mode: ThemeMode.dark,
        textScale: 2,
      );
      expect(find.text('暫無公告'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
