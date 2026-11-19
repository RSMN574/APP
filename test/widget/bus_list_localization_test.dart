import 'package:com.rsmn574.app/features/bus/widgets/bus_list.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/models/bus_route.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final route = BusRoute(
    routeUID: 'route-1',
    routeID: '1',
    hasSubRoutes: false,
    operators: const [],
    subRoutes: const [],
    routeName: const {'Zh_tw': '市區公車 1', 'En': 'City Bus 1'},
    departureStopNameZh: '臺北車站',
    departureStopNameEn: 'Taipei Main Station',
    destinationStopNameZh: '市政府',
    destinationStopNameEn: 'City Hall',
    city: 'Taipei',
    cityCode: 'Taipei',
    updateTime: DateTime(2026),
    versionID: 1,
  );

  Future<void> pumpBusList(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Buslist(suggestions: [route], city: 'Taipei'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows English route and stop names in English locale',
      (tester) async {
    await pumpBusList(tester, const Locale('en'));

    expect(find.text('City Bus 1'), findsOneWidget);
    expect(find.text('Starting point: Taipei Main Station'), findsOneWidget);
    expect(find.text('Destination: City Hall'), findsOneWidget);
  });

  testWidgets(
      'shows Traditional Chinese route and stop names in Chinese locale',
      (tester) async {
    await pumpBusList(tester, const Locale('zh'));

    expect(find.text('市區公車 1'), findsOneWidget);
    expect(find.text('起點: 臺北車站'), findsOneWidget);
    expect(find.text('終點: 市政府'), findsOneWidget);
  });
}
