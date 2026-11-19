import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/features/transit_alerts/data/transit_alert_adapters.dart';
import 'package:com.rsmn574.app/features/transit_alerts/data/transit_alert_repository.dart';
import 'package:com.rsmn574.app/features/transit_alerts/models/transit_alert.dart';
import 'package:com.rsmn574.app/features/transit_alerts/state/transit_alert_provider.dart';
import 'package:com.rsmn574.app/features/transit_alerts/widgets/transit_alert_center.dart';
import 'package:com.rsmn574.app/features/transit_alerts/data/transit_alert_service.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

TransitAlert _alert({
  String id = 'id',
  AlertSeverity severity = AlertSeverity.info,
  DateTime? updatedAt,
}) {
  return TransitAlert(
    id: id,
    title: 'title',
    description: 'description',
    transportType: TransportType.bus,
    alertType: AlertType.generalNotice,
    severity: severity,
    affectedRoutes: const [],
    affectedStops: const [],
    location: null,
    startTime: null,
    endTime: null,
    publishedAt: updatedAt,
    updatedAt: updatedAt,
    source: 'test',
    sourceUrl: null,
    status: AlertStatus.active,
  );
}

void main() {
  group('TransitAlert', () {
    test('parses missing and invalid values safely', () {
      final alert = TransitAlert.fromJson({
        'id': 'a1',
        'title': '公告',
        'transportType': 'bus',
        'severity': 'not-valid',
        'startTime': 'not-a-date',
        'affectedRoutes': ['307', null, ''],
      });

      expect(alert.id, 'a1');
      expect(alert.description, isEmpty);
      expect(alert.severity, AlertSeverity.unknown);
      expect(alert.startTime, isNull);
      expect(alert.affectedRoutes, ['307']);
      expect(alert.toJson()['transportType'], 'bus');
      expect(alert.rawData['id'], 'a1');
    });
  });

  group('TransitAlertRepository', () {
    test('deduplicates alerts and keeps source failures isolated', () async {
      final result = await TransitAlertRepository(
        adapters: [
          _FakeAdapter('ok', [_alert(id: 'same')]),
          _FakeAdapter(
              'duplicate', [_alert(id: 'same', severity: AlertSeverity.major)]),
          _FakeAdapter('failed', const [], StateError('offline')),
        ],
      ).fetchAlerts();

      expect(result.alerts, hasLength(1));
      expect(result.alerts.single.severity, AlertSeverity.major);
      expect(result.sourceErrors.keys, contains('failed'));
    });

    test('maps the three TDX response shapes through independent adapters',
        () async {
      final client = _FakeTdxApi({
        '/api/basic/v2/Bus/Alert/City/Taichung': [
          {
            'AlertID': 'bus-1',
            'AlertType': 'Delay',
            'Description': '公車延誤',
            'RouteID': '307',
            'Road': '中港路',
            'UpdateTime': '2026-11-15T01:00:00+08:00',
          },
        ],
        '/api/basic/v2/Rail/Metro/Alert/TYMC': [
          {
            'AlertID': 'metro-1',
            'Effect': '設備異常',
            'Description': {'Zh_tw': '桃園捷運設備異常'},
            'LineID': 'A',
            'StationID': 'A12',
            'UpdateTime': '2026-11-15T01:10:00+08:00',
          },
        ],
        '/api/basic/v2/Rail/THSR/AlertInfo': [
          {
            'AlertID': 'thsr-1',
            'Status': '營運資訊',
            'Description': '高鐵公告',
            'StartDate': '2026-11-15',
            'EndDate': '2026-11-16',
            'UpdateTime': '2026-11-15T01:20:00+08:00',
          },
        ],
      });

      final alerts = await TransitAlertRepository(
        service: _FakeService(client),
      ).fetchAlerts();

      expect(alerts.alerts.map((item) => item.id),
          containsAll(<String>['bus-1', 'metro-1', 'thsr-1']));
      expect(
        alerts.alerts.firstWhere((item) => item.id == 'bus-1').affectedRoutes,
        ['307'],
      );
      expect(
        alerts.alerts.firstWhere((item) => item.id == 'metro-1').affectedStops,
        ['A12'],
      );
      expect(alerts.alerts.firstWhere((item) => item.id == 'thsr-1').startTime,
          isNotNull);
      expect(client.paths, hasLength(3));
      expect(
        client.queries.every(
          (query) => query?['\$top'] == '30' && query?['\$format'] == 'JSON',
        ),
        isTrue,
      );
    });

    test('malformed JSON from one source does not hide other sources',
        () async {
      final client = _FakeTdxApi({
        '/api/basic/v2/Bus/Alert/City/Taichung': {'invalid': true},
        '/api/basic/v2/Rail/Metro/Alert/TYMC': [
          {'AlertID': 'metro-ok', 'Description': 'ok'},
        ],
        '/api/basic/v2/Rail/THSR/AlertInfo': <dynamic>[],
      });

      final result = await TransitAlertRepository(
        service: _FakeService(client),
      ).fetchAlerts();

      expect(result.alerts.single.id, 'metro-ok');
      expect(result.sourceErrors.keys, contains('台中市公車'));
    });
  });

  test('provider sorts severity before time and reuses in-flight request',
      () async {
    final provider = TransitAlertProvider(
      repository: TransitAlertRepository(
        adapters: [
          _FakeAdapter('test', [
            _alert(
                id: 'old-major',
                severity: AlertSeverity.major,
                updatedAt: DateTime(2024)),
            _alert(id: 'new-info', updatedAt: DateTime(2026)),
          ]),
        ],
      ),
    );

    final first = provider.load();
    final second = provider.load();
    expect(identical(first, second), isTrue);
    await first;

    expect(provider.alerts.map((item) => item.id), ['old-major', 'new-info']);
    provider.dispose();
  });

  test('maps real TDX shapes: Metro wrapper object, Scope and PublishTime',
      () async {
    // 結構取自 2026-11-16 實際 TDX 回應。
    final client = _FakeTdxApi({
      '/api/basic/v2/Bus/Alert/City/Taichung': [
        {
          'AlertID': '404451974',
          'Title': '施工改道',
          'Description': '取消停靠',
          'Status': 2,
          'Cause': 4,
          'Effect': 1,
          'Scope': {
            'Routes': [
              {
                'RouteID': '219',
                'RouteName': {'Zh_tw': '219', 'En': ''},
                'Direction': 0,
              },
            ],
          },
          'PublishTime': '2026-11-13T00:00:00+08:00',
          'StartTime': '2026-11-13T12:44:05+08:00',
          'EndTime': '2099-11-16T23:59:59+08:00',
          'SrcUpdateTime': '2099-11-16T23:59:59+08:00',
          'UpdateTime': '2026-11-16T00:06:50+08:00',
        },
      ],
      '/api/basic/v2/Rail/Metro/Alert/TYMC': {
        'UpdateTime': '2026-11-16T21:34:04+08:00',
        'AuthorityCode': 'TYMC',
        'Alerts': [
          {
            'AlertID': '20261116213001',
            'Title': '正常營運',
            'Description': '正常營運',
            'Status': 1,
            'Scope': {
              'Network': {},
              'Stations': [],
              'Lines': [],
            },
            'PublishTime': '2026-11-16T21:30:01+08:00',
            'UpdateTime': '2026-11-16T21:30:01+08:00',
          },
        ],
      },
      '/api/basic/v2/Rail/THSR/AlertInfo': [
        {
          'AlertID': '00000000-0000-0000-0000-000000000000',
          'Title': '全線營運正常(Normal)',
          'Status': '',
          'StartTime': '0001-01-01T00:00:00+08:06',
          'PublishTime': '2026-11-16T21:32:08+08:00',
          'UpdateTime': '2026-11-16T21:32:08+08:00',
        },
      ],
    });

    final result = await TransitAlertRepository(
      service: _FakeService(client),
    ).fetchAlerts();

    expect(result.sourceErrors, isEmpty);
    final bus = result.alerts.firstWhere((a) => a.id == '404451974');
    expect(bus.affectedRoutes, ['219']);
    expect(bus.publishedAt, DateTime.parse('2026-11-13T00:00:00+08:00'));
    expect(
      result.alerts.any((a) => a.transportType == TransportType.metro),
      isTrue,
    );
    final thsr =
        result.alerts.firstWhere((a) => a.transportType == TransportType.thsr);
    expect(thsr.startTime, isNull);
  });

  test('active alerts sort before expired alerts of the same severity',
      () async {
    TransitAlert withStatus(String id, AlertStatus status) => TransitAlert(
          id: id,
          title: id,
          description: '',
          transportType: TransportType.bus,
          alertType: AlertType.generalNotice,
          severity: AlertSeverity.info,
          affectedRoutes: const [],
          affectedStops: const [],
          location: null,
          startTime: null,
          endTime: null,
          publishedAt: null,
          updatedAt: null,
          source: 'test',
          sourceUrl: null,
          status: status,
        );
    final provider = TransitAlertProvider(
      repository: TransitAlertRepository(adapters: [
        _FakeAdapter('s', [
          withStatus('old', AlertStatus.expired),
          withStatus('now', AlertStatus.active),
        ]),
      ]),
    );
    await provider.load();
    expect(provider.alerts.map((a) => a.id), ['now', 'old']);
  });

  test('unconnected adapters never expose fake alerts', () async {
    expect(await AviationTransitAlertAdapter().fetchAlerts(), isEmpty);
  });

  testWidgets('announcement center renders an empty source state',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TransitAlertProvider(repository: _EmptyRepository()),
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TransitAlertCenter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('交通公告中心'), findsOneWidget);
    expect(find.text('目前尚無可顯示的交通公告；公告來源尚未串接'), findsOneWidget);
  });
}

class _FakeAdapter implements TransitAlertAdapter {
  _FakeAdapter(this.sourceName, this.alerts, [this.error]);

  @override
  final String sourceName;
  final List<TransitAlert> alerts;
  final Object? error;

  @override
  Future<List<TransitAlert>> fetchAlerts() {
    if (error != null) return Future.error(error!);
    return Future.value(alerts);
  }
}

class _FakeTdxApi extends TdxApiClient {
  _FakeTdxApi(this.responses);

  final Map<String, dynamic> responses;
  final paths = <String>[];
  final queries = <Map<String, String>?>[];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    Future<void>? abortTrigger,
  }) async {
    paths.add(path);
    queries.add(queryParams);
    final response = responses[path];
    if (response is Exception) throw response;
    return response;
  }
}

class _FakeService extends TransitAlertService {
  _FakeService(this.fakeClient) : super(client: fakeClient);

  final _FakeTdxApi fakeClient;
}

class _EmptyRepository extends TransitAlertRepository {
  @override
  Future<TransitAlertFetchResult> fetchAlerts() async =>
      TransitAlertFetchResult(
        alerts: const [],
        sourceErrors: const {},
        updatedAt: DateTime.now(),
      );
}
