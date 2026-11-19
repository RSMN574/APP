import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/core/cache/api_cache.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_schedule_remote_data_source.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_schedule_repository.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_daily_timetable.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_schedule_page.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_schedule_provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _fixture =
    File('test/fixtures/tdx/daily_stop_timetable_taichung_300.json')
        .readAsStringSync();

/// 讓 fixture 的 BusDate/時間對應「今天」，測試結果不受執行日期影響。
String _fixtureForToday(DateTime twNow) {
  final date =
      '${twNow.year.toString().padLeft(4, '0')}-${twNow.month.toString().padLeft(2, '0')}-${twNow.day.toString().padLeft(2, '0')}';
  return _fixture.replaceAll(
      RegExp(r'\d{4}-\d{2}-\d{2}T00:00:00\+08:00'), '${date}T00:00:00+08:00');
}

BusScheduleRepository _repo(http.Response Function() responder,
    {Completer<void>? gate}) {
  return BusScheduleRepository(
    remote: BusScheduleRemoteDataSource(
      client: TdxApiClient(
        loadToken: () async => 't',
        refreshToken: () async => 't',
        clientFactory: () => MockClient((_) async {
          if (gate != null) await gate.future;
          return responder();
        }),
      ),
      parser: (body) async => parseBusDailyTimetables(jsonDecode(body)),
    ),
    cache: MemoryApiCache(),
  );
}

Widget _app(Widget child,
    {ThemeMode mode = ThemeMode.light,
    double textScale = 1.0,
    Locale locale = const Locale('zh')}) {
  return MaterialApp(
    theme: AppThemes.lightTheme,
    darkTheme: AppThemes.darkTheme,
    themeMode: mode,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
    home: child,
  );
}

void main() {
  final twNow = DateTime.now().toUtc().add(const Duration(hours: 8));

  group('BusScheduleProvider', () {
    test('unsupported city never hits the network', () async {
      var calls = 0;
      final p = BusScheduleProvider(
        city: '臺北市',
        routeName: '307',
        repository: _repo(() {
          calls++;
          return http.Response('[]', 200);
        }),
      );
      await p.load();
      expect(p.status, BusScheduleStatus.unsupported);
      expect(calls, 0);
    });

    test('loads, exposes stops and computes the next departure', () async {
      final p = BusScheduleProvider(
        city: 'Taichung',
        routeName: '300',
        routeId: '300',
        repository: _repo(() =>
            http.Response.bytes(utf8.encode(_fixtureForToday(twNow)), 200)),
        clock: () => DateTime.utc(twNow.year, twNow.month, twNow.day, 0, 0)
            .subtract(const Duration(hours: 8))
            .add(const Duration(hours: 12)), // 台灣時間 12:00
      );
      await p.load();
      expect(p.status, BusScheduleStatus.loaded);
      expect(p.isOutdated, isFalse);
      expect(p.stops, hasLength(2));
      final next = p.nextDeparture!;
      expect(next.departure.minutesFromServiceDayStart,
          greaterThanOrEqualTo(12 * 60));
      p.selectStop(1);
      expect(p.selectedStop!.stopId, isNot(p.stops.first.stopId));
    });

    test('flags timetables whose BusDate is not today', () async {
      final p = BusScheduleProvider(
        city: 'Taichung',
        routeName: '300',
        routeId: '300',
        repository:
            _repo(() => http.Response.bytes(utf8.encode(_fixture), 200)),
        clock: () => DateTime.utc(2030, 1, 1),
      );
      await p.load();
      expect(p.isOutdated, isTrue);
      expect(p.nextDeparture, isNull,
          reason: 'never present an old date as today\'s next bus');
    });

    test('network failure becomes an error state', () async {
      final p = BusScheduleProvider(
        city: 'Taichung',
        routeName: '300',
        routeId: '300',
        repository: _repo(() => throw const SocketException('offline')),
      );
      await p.load();
      expect(p.status, BusScheduleStatus.error);
      expect(p.errorCategory!.name, 'network');
    });
  });

  group('BusSchedulePage widget', () {
    testWidgets('shows loading, then the timetable with the ETA disclaimer',
        (tester) async {
      final gate = Completer<void>();
      await tester.pumpWidget(_app(BusSchedulePage(
        city: 'Taichung',
        routeName: '300',
        routeId: '300',
        repository: _repo(
            () =>
                http.Response.bytes(utf8.encode(_fixtureForToday(twNow)), 200),
            gate: gate),
      )));
      await tester.pump();
      expect(find.text('正在載入班表…'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('300 班表'), findsOneWidget);
      expect(find.textContaining('並非即時預估到站時間'), findsOneWidget);
      expect(find.textContaining('共 108 班'), findsOneWidget);
      expect(find.text('05:46'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unsupported city shows a clear message', (tester) async {
      await tester.pumpWidget(_app(BusSchedulePage(
        city: 'Taipei',
        routeName: '307',
        repository: _repo(() => http.Response('[]', 200)),
      )));
      await tester.pumpAndSettle();
      expect(find.text('此縣市尚未提供班表'), findsOneWidget);
      expect(find.textContaining('臺北市 尚未支援'), findsOneWidget);
    });

    testWidgets('empty response shows the empty state', (tester) async {
      await tester.pumpWidget(_app(BusSchedulePage(
        city: 'Kaohsiung',
        routeName: '紅3',
        routeId: '15201',
        repository: _repo(() => http.Response('[]', 200)),
      )));
      await tester.pumpAndSettle();
      expect(find.text('此路線目前沒有提供每日班表。'), findsOneWidget);
    });

    testWidgets('offline error offers retry that recovers', (tester) async {
      var online = false;
      await tester.pumpWidget(_app(BusSchedulePage(
        city: 'Taichung',
        routeName: '300',
        routeId: '300',
        repository: _repo(() {
          if (!online) throw const SocketException('offline');
          return http.Response.bytes(utf8.encode(_fixtureForToday(twNow)), 200);
        }),
      )));
      await tester.pumpAndSettle();
      expect(find.text('無法載入班表，請檢查網路後重試。'), findsOneWidget);

      online = true;
      await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('共 108 班'), findsOneWidget);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
          'renders without overflow in $mode at 2x text on a small phone',
          (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(
          BusSchedulePage(
            city: 'Taichung',
            routeName: '300',
            routeId: '300',
            repository: _repo(() =>
                http.Response.bytes(utf8.encode(_fixtureForToday(twNow)), 200)),
          ),
          mode: mode,
          textScale: 2.0,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
      });
    }

    testWidgets('English locale uses English labels', (tester) async {
      await tester.pumpWidget(_app(
        BusSchedulePage(
          city: 'Taichung',
          routeName: '300',
          routeId: '300',
          repository: _repo(() =>
              http.Response.bytes(utf8.encode(_fixtureForToday(twNow)), 200)),
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('300 Timetable'), findsOneWidget);
      expect(find.textContaining('Taichung Station'), findsWidgets);
    });
  });
}
