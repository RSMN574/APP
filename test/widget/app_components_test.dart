import 'package:com.rsmn574.app/const/arrival_status_colors.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/core/transit/arrival_status.dart';
import 'package:com.rsmn574.app/widget/app_components.dart';
import 'package:com.rsmn574.app/widget/arrival_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child,
    {ThemeMode mode = ThemeMode.light, double scale = 1}) {
  return MaterialApp(
    theme: AppThemes.lightTheme,
    darkTheme: AppThemes.darkTheme,
    themeMode: mode,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('ArrivalChip renders every status at 2x text ($mode)',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(
        Wrap(children: [
          for (final s in ArrivalStatus.values)
            ArrivalChip(status: s, label: '12 分'),
        ]),
        mode: mode,
        scale: 2,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('12 分'), findsNWidgets(ArrivalStatus.values.length));
    });
  }

  testWidgets('ArrivalChip uses theme tokens, scheduled is outlined',
      (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [
      ArrivalChip(status: ArrivalStatus.arriving, label: 'A'),
      ArrivalChip(status: ArrivalStatus.scheduled, label: 'S'),
    ])));
    final arriving = tester.widget<Container>(find
        .ancestor(of: find.text('A'), matching: find.byType(Container))
        .first);
    final deco = arriving.decoration! as ShapeDecoration;
    expect(deco.color, ArrivalStatusColors.light.arrivingBackground);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget,
        reason: '固定班表需有時鐘圖示，不可與即時資料混淆');
  });

  testWidgets(
      'AppCard, AppIconContainer and AppSectionHeader render in dark mode',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(
      Column(mainAxisSize: MainAxisSize.min, children: [
        const AppSectionHeader(title: '常用路線'),
        AppCard(onTap: () => tapped++, child: const Text('卡片')),
        const AppIconContainer(circle: true, child: Icon(Icons.directions_bus)),
      ]),
      mode: ThemeMode.dark,
    ));
    await tester.tap(find.text('卡片'));
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showAppDialog returns the chosen action', (tester) async {
    bool? result;
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showAppDialog(
          context,
          title: '刪除收藏？',
          confirmLabel: '刪除',
          cancelLabel: '取消',
          destructive: true,
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('AppSearchField shows clear button only with text',
      (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(
        _wrap(SizedBox(width: 300, child: AppSearchField(controller: c))));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.enterText(find.byType(TextField), '300');
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(c.text, isEmpty);
  });
}
