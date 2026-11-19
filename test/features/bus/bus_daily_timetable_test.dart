import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/features/bus/model/bus_daily_timetable.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/tdx/$name').readAsStringSync());

void main() {
  group('BusClockTime', () {
    test('parses HH:mm and keeps cross-day hours', () {
      expect(BusClockTime.tryParse('05:46')!.minutesFromServiceDayStart, 346);
      final late = BusClockTime.tryParse('24:30')!;
      expect(late.isNextDay, isTrue);
      expect(late.format(), '00:30');
      expect(BusClockTime.tryParse('7:05')!.format(), '07:05');
    });

    test('rejects malformed times', () {
      for (final bad in [null, '', '12', '12:60', '48:00', 'ab:cd', 1230]) {
        expect(BusClockTime.tryParse(bad), isNull, reason: '$bad');
      }
    });
  });

  group('parseBusDailyTimetables with real TDX responses', () {
    test('Taichung 300 matches the OAS schema and is sorted', () {
      final result = parseBusDailyTimetables(
          _fixture('daily_stop_timetable_taichung_300.json'));
      expect(result.skippedRecords, 0);
      expect(result.skippedEntries, 0);
      expect(result.timetables, hasLength(1));
      final t = result.timetables.single;
      expect(t.routeId, '300');
      expect(t.routeName.zhTw, '300');
      expect(t.destinationStopName?.zhTw, '臺中車站(A月台)');
      expect(t.busDate, isNotNull);
      expect(t.updateTime, isNotNull);
      expect(t.stops, hasLength(2));
      expect(t.tripCount, 108);
      expect(t.isEstimatedOnly, isTrue, reason: 'TimeType=0 in live data');
      final times = t.stops.first.entries.map((e) => e.departure).toList();
      final sorted = [...times]..sort();
      expect(times, sorted);
      expect(t.stops.first.firstDeparture!.format(), '05:46');
    });

    test('Taoyuan route 1 returns two directions', () {
      final result = parseBusDailyTimetables(
          _fixture('daily_stop_timetable_taoyuan_1_trimmed.json'));
      expect(result.timetables.map((t) => t.destinationStopName?.zhTw),
          ['中壢分局', '桃園巨蛋']);
      expect(result.timetables.every((t) => t.hasAnyTime), isTrue);
    });
  });

  group('parseBusDailyTimetables edge cases', () {
    test('empty array is a valid empty result', () {
      final r = parseBusDailyTimetables(<Object?>[]);
      expect(r.timetables, isEmpty);
    });

    test('non-array response throws FormatException', () {
      expect(() => parseBusDailyTimetables({'Message': 'error'}),
          throwsFormatException);
      expect(() => parseBusDailyTimetables(null), throwsFormatException);
    });

    test('missing fields, nulls and bad times are skipped, not fatal', () {
      final r = parseBusDailyTimetables([
        null,
        {
          'RouteName': {'Zh_tw': 'x'}
        }, // 缺 RouteID
        {
          'RouteID': '1',
          'RouteName': {'Zh_tw': '1', 'En': null},
          'SubRouteName': null,
          'DestinationStopName': null,
          'BusDate': 'not-a-date',
          'Stops': [
            {
              'StopUID': 'A',
              'StopID': 'A',
              'StopName': null,
              'TimeTables': null
            },
            {
              'StopUID': 'B',
              'StopID': 'B',
              'TimeTables': [
                {
                  'Sequence': 2,
                  'ArrivalTime': '09:00',
                  'DepartureTime': '09:00',
                  'TimeType': 1
                },
                {
                  'Sequence': 1,
                  'ArrivalTime': '25:99',
                  'DepartureTime': 'bad',
                  'TimeType': 0
                },
                {'Sequence': 3, 'DepartureTime': '08:00', 'TimeType': 9},
                'garbage',
              ],
            },
          ],
        },
      ]);
      expect(r.skippedRecords, 2);
      expect(r.skippedEntries, 2);
      final t = r.timetables.single;
      expect(t.busDate, isNull);
      expect(t.destinationStopName, isNull);
      expect(t.stops.first.entries, isEmpty);
      final entries = t.stops.last.entries;
      expect(entries.map((e) => e.departure.format()), ['08:00', '09:00']);
      expect(entries.first.timeType, BusTimeType.unknown);
      expect(entries.first.arrival.format(), '08:00',
          reason: 'missing ArrivalTime falls back to DepartureTime');
      expect(entries.last.timeType, BusTimeType.scheduled);
    });

    test('toJson round-trips through the parser', () {
      final original = parseBusDailyTimetables(
              _fixture('daily_stop_timetable_taichung_300.json'))
          .timetables;
      final again = parseBusDailyTimetables(
          jsonDecode(jsonEncode([for (final t in original) t.toJson()])));
      expect(again.timetables.single.tripCount, original.single.tripCount);
      expect(again.timetables.single.busDate, original.single.busDate);
    });
  });
}
