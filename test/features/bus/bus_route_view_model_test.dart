import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/core/error/app_error_handler.dart';
import 'package:com.rsmn574.app/core/transit/arrival_status.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_route_stops_builder.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_route_view_model.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _stop(String uid, String zh, String en) => {
      'StopUID': uid,
      'StopID': uid,
      'StopName': {'Zh_tw': zh, 'En': en},
      'StopPosition': {'PositionLat': 24.1, 'PositionLon': 120.6},
    };

final _routeStops = <Map<String, dynamic>>[
  {
    'Direction': 0,
    'Stops': jsonEncode([
      _stop('A', '靜宜大學', 'Providence Univ.'),
      _stop('B', '市政府', 'City Hall'),
      _stop('C', '臺中車站', 'Taichung Station'),
    ]),
  },
  {
    'Direction': 1,
    'Stops': jsonEncode([
      _stop('C', '臺中車站', 'Taichung Station'),
      _stop('A', '靜宜大學', 'Providence Univ.'),
    ]),
  },
];

final _arrivals = <dynamic>[
  {
    'Direction': 0,
    'StopUID': 'A',
    'EstimateTime': 30,
    'Estimates': [
      {'PlateNumb': 'KKA-5776', 'EstimateTime': 30},
    ],
  },
  {'Direction': 0, 'StopUID': 'B', 'EstimateTime': 600},
  {'Direction': 1, 'StopUID': 'C', 'EstimateTime': 120},
];

class _FakeSource implements BusRouteDataSource {
  int calls = 0;
  Object? failWith;

  @override
  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  }) async {
    if (failWith != null) throw failWith!;
    return _arrivals;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRouteStops({
    required String city,
    required String routeId,
  }) async {
    calls++;
    if (failWith != null) throw failWith!;
    return _routeStops;
  }
}

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final now = DateTime(2026, 11, 20, 8);

  setUp(AppErrorHandler.reset);

  group('BusRouteStopsBuilder', () {
    test('merges stops with arrivals per direction', () {
      final rows = BusRouteStopsBuilder.build(
        direction: 0,
        busTimeData: _arrivals,
        routeStopsData: _routeStops,
        l10n: zh,
        isEnglish: false,
        now: now,
      );
      expect(rows.map((r) => r['stopName']), ['靜宜大學', '市政府', '臺中車站']);
      expect(rows[0]['arrivalStatus'], ArrivalStatus.arriving);
      expect(rows[0]['PlateNumb'], 'KKA-5776');
      expect(rows[1]['arrivalStatus'], ArrivalStatus.minutes);
      expect(rows[2]['arrivalStatus'], ArrivalStatus.ended);
      expect(rows[2]['hasLiveData'], isFalse);
    });

    test('English display names and highlight only on the marked direction',
        () {
      final rows = BusRouteStopsBuilder.build(
        direction: 1,
        busTimeData: _arrivals,
        routeStopsData: _routeStops,
        l10n: lookupAppLocalizations(const Locale('en')),
        isEnglish: true,
        now: now,
        highlightStops: ['臺中車站'],
        highlightDirection: 1,
      );
      expect(rows.first['displayStopName'], 'Taichung Station');
      expect(rows.first['stopName'], '臺中車站');
      expect(rows.first['isHighlighted'], isTrue);
      expect(rows.first['arrivalStatus'], ArrivalStatus.approaching);
    });

    test('missing direction or broken JSON yields an empty list', () {
      expect(
        BusRouteStopsBuilder.build(
          direction: 5,
          busTimeData: _arrivals,
          routeStopsData: _routeStops,
          l10n: zh,
          isEnglish: false,
          now: now,
        ),
        isEmpty,
      );
      expect(
        BusRouteStopsBuilder.build(
          direction: 0,
          busTimeData: const [],
          routeStopsData: [
            {'Direction': 0, 'Stops': '{broken'}
          ],
          l10n: zh,
          isEnglish: false,
          now: now,
        ),
        isEmpty,
      );
    });

    test('parses pseudo JSON estimates restored from the database', () {
      final list = BusRouteStopsBuilder.parseEstimates(
          '[{PlateNumb: 739-U5, EstimateTime: 60}]');
      expect(list.single['PlateNumb'], '739-U5');
      expect(list.single['EstimateTime'], 60);
    });
  });

  group('BusRouteViewModel', () {
    BusRouteViewModel vm(_FakeSource source, {bool subRoutes = true}) =>
        BusRouteViewModel(
          dataSource: source,
          city: 'Taichung',
          routeId: '300',
          tdxRouteName: '300',
          hasSubRoutes: subRoutes,
          tabCount: subRoutes ? 2 : 1,
          preferredDirection: 1,
          clock: () => now,
        );

    test('loads both directions, starts the countdown for live data', () async {
      final source = _FakeSource();
      final model = vm(source);
      await model.load(l10n: zh, isEnglish: false);
      expect(model.status, BusRouteLoadStatus.loaded);
      expect(model.stopsForTab(0), isNotEmpty);
      expect(model.stopsForTab(1), isNotEmpty);
      expect(model.autoReloadOn.value, isTrue);
      expect(model.remainingSeconds.value, 40);
      model.dispose();
    });

    test('initial tab follows the tapped direction exactly once', () async {
      final model = vm(_FakeSource());
      await model.load(l10n: zh, isEnglish: false);
      final first = model.takeInitialTabIndex();
      expect(first, isNotNull);
      expect(model.directionForTab(first!), 1);
      await model.load(l10n: zh, isEnglish: false);
      expect(model.takeInitialTabIndex(), isNull);
      model.dispose();
    });

    test('first failure becomes an error state', () async {
      final model = vm(_FakeSource()..failWith = const SocketException('x'));
      await model.load(l10n: zh, isEnglish: false);
      expect(model.status, BusRouteLoadStatus.error);
      expect(model.hasData, isFalse);
      model.dispose();
    });

    test('later failure keeps previous data and rethrows for a hint', () async {
      final source = _FakeSource();
      final model = vm(source);
      await model.load(l10n: zh, isEnglish: false);
      source.failWith = TimeoutException('slow');
      await expectLater(model.load(l10n: zh, isEnglish: false),
          throwsA(isA<TimeoutException>()));
      expect(model.status, BusRouteLoadStatus.loaded);
      expect(model.stopsForTab(0), isNotEmpty);
      model.dispose();
    });

    testWidgets('countdown reaches zero and calls onAutoReload',
        (tester) async {
      final source = _FakeSource();
      final model = BusRouteViewModel(
        dataSource: source,
        city: 'Taichung',
        routeId: '300',
        tdxRouteName: '300',
        hasSubRoutes: false,
        tabCount: 1,
        autoReloadSeconds: 3,
        clock: () => now,
      );
      var reloads = 0;
      model.onAutoReload = () async => reloads++;
      // 在 FakeAsync zone 內載入，Timer 才會受 tester.pump 控制。
      final loading = model.load(l10n: zh, isEnglish: false);
      await tester.pump();
      await loading;
      expect(model.autoReloadOn.value, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(reloads, 1);
      expect(model.remainingSeconds.value, 3);
      model.dispose();
    });
  });
}
