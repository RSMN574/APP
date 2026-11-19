import 'package:com.rsmn574.app/features/bus/services/bus_stop_time_formatter.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 20, 8, 0);

  for (final locale in const [Locale('zh'), Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);

    group('BusStopTimeFormatter (${locale.languageCode})', () {
      ArrivalStatus statusOf(Map<String, dynamic>? stop) =>
          BusStopTimeFormatter.format(stopTime: stop, l10n: l10n, now: now)
              .status;

      test('status never depends on the localized text', () {
        expect(statusOf(null), ArrivalStatus.ended);
        expect(statusOf({'EstimateTime': 0}), ArrivalStatus.arriving);
        expect(statusOf({'EstimateTime': 30}), ArrivalStatus.arriving);
        expect(statusOf({'EstimateTime': 120}), ArrivalStatus.approaching);
        expect(statusOf({'EstimateTime': 600}), ArrivalStatus.minutes);
        expect(statusOf({}), ArrivalStatus.ended);
      });

      test('NextBusTime maps to arriving / minutes / not departed / ended', () {
        String iso(Duration d) => now.add(d).toIso8601String();
        expect(statusOf({'NextBusTime': iso(const Duration(seconds: 30))}),
            ArrivalStatus.arriving);
        expect(statusOf({'NextBusTime': iso(const Duration(minutes: 2))}),
            ArrivalStatus.approaching);
        expect(statusOf({'NextBusTime': iso(const Duration(minutes: 20))}),
            ArrivalStatus.minutes);
        final later = BusStopTimeFormatter.format(
          stopTime: {'NextBusTime': iso(const Duration(hours: 2))},
          l10n: l10n,
          now: now,
        );
        expect(later.status, ArrivalStatus.notDeparted);
        expect(later.displayTime, '10:00');
        expect(statusOf({'NextBusTime': iso(const Duration(minutes: -10))}),
            ArrivalStatus.ended);
      });

      test('minute text is localized in every branch', () {
        final a = BusStopTimeFormatter.format(
          stopTime: {
            'NextBusTime': now.add(const Duration(minutes: 2)).toIso8601String()
          },
          l10n: l10n,
          now: now,
        );
        expect(a.displayTime, l10n.nearStopMinutes('2'),
            reason: '先前此分支寫死「分鐘」，英文介面會顯示中文');
      });

      test('only live statuses are marked live', () {
        expect(ArrivalStatus.arriving.isLive, isTrue);
        expect(ArrivalStatus.minutes.isLive, isTrue);
        expect(ArrivalStatus.notDeparted.isLive, isFalse);
        expect(ArrivalStatus.scheduled.isLive, isFalse);
        expect(ArrivalStatus.ended.isInactive, isTrue);
      });
    });
  }
}
