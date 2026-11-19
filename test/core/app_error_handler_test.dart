import 'dart:async';
import 'dart:io';

import 'package:com.rsmn574.app/core/error/app_error_handler.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'package:com.rsmn574.app/firebase/performance_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeReporter implements ErrorReporter {
  final errors = <(String, bool, String?)>[];
  final flutterErrors = <(String, bool)>[];
  final logs = <String>[];
  final keys = <String, Object>{};

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {required bool fatal, String? reason}) async {
    errors.add((error.toString(), fatal, reason));
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
      {required bool fatal}) async {
    flutterErrors.add((details.exceptionAsString(), fatal));
  }

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      keys[key] = value;
}

void main() {
  late _FakeReporter reporter;

  setUp(() {
    AppErrorHandler.reset();
    reporter = _FakeReporter();
    AppErrorHandler.attachReporter(reporter);
  });

  tearDown(AppErrorHandler.reset);

  group('classify', () {
    test('maps common exceptions to stable categories', () {
      expect(AppErrorHandler.classify(TimeoutException('x')),
          AppErrorCategory.timeout);
      expect(AppErrorHandler.classify(const SocketException('x')),
          AppErrorCategory.network);
      expect(AppErrorHandler.classify(http.ClientException('x')),
          AppErrorCategory.network);
      expect(AppErrorHandler.classify(const FormatException('x')),
          AppErrorCategory.parse);
      expect(AppErrorHandler.classify(const TdxRequestCancelledException()),
          AppErrorCategory.cancelled);
      expect(
          AppErrorHandler.classify(
              const HttpException('TDX API error: 401 - Unauthorized')),
          AppErrorCategory.auth);
      expect(AppErrorHandler.classify(const HttpException('HTTP 429')),
          AppErrorCategory.rateLimited);
      expect(AppErrorHandler.classify(const HttpException('status 503')),
          AppErrorCategory.server);
      expect(
          AppErrorHandler.classify(
              const HttpException('TDX token is unavailable')),
          AppErrorCategory.auth);
      expect(
          AppErrorHandler.classify(Exception('?')), AppErrorCategory.unknown);
    });
  });

  group('sanitize', () {
    test('removes tokens, query strings, emails and secrets', () {
      const raw = 'GET https://tdx.transportdata.tw/api/x?\$filter=a&token=abc '
          'Authorization: Bearer abc.def-ghi eyJhbGciOi.eyJzdWIiOi.c2lnbmF0dXJl '
          'user nick@example.com password=hunter2 api_key: XYZ';
      final clean = AppErrorHandler.sanitize(raw);
      expect(clean, isNot(contains('abc.def-ghi')));
      expect(clean, isNot(contains('eyJhbGciOi')));
      expect(clean, isNot(contains('nick@example.com')));
      expect(clean, isNot(contains('hunter2')));
      expect(clean, isNot(contains('XYZ')));
      expect(clean, isNot(contains('filter=a')));
      expect(clean, contains('https://tdx.transportdata.tw/api/x?<query>'));
    });

    test('truncates very long messages', () {
      expect(AppErrorHandler.sanitize('a' * 5000).length, lessThan(1100));
    });
  });

  group('reporting', () {
    test('non-fatal errors are sanitized and tagged', () async {
      await AppErrorHandler.recordNonFatal(
        const HttpException('TDX API error: 500 Bearer secret-token'),
        StackTrace.current,
        feature: 'bus_schedule',
      );
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single.$1, isNot(contains('secret-token')));
      expect(reporter.errors.single.$2, isFalse);
      expect(reporter.keys['error_category'], 'server');
      expect(reporter.keys['feature'], 'bus_schedule');
    });

    test('duplicate errors inside the window are reported once', () async {
      final stack = StackTrace.current;
      for (var i = 0; i < 5; i++) {
        await AppErrorHandler.recordNonFatal(
            const SocketException('offline'), stack,
            feature: 'bus');
      }
      expect(reporter.errors, hasLength(1));
      await AppErrorHandler.recordNonFatal(
          const SocketException('offline'), stack,
          feature: 'metro');
      expect(reporter.errors, hasLength(2), reason: 'different feature');
    });

    test('cancelled requests are not reported as non-fatal', () async {
      await AppErrorHandler.recordNonFatal(
          const TdxRequestCancelledException(), null);
      expect(reporter.errors, isEmpty);
    });

    test('layout errors are non-fatal, unknown framework errors fatal', () {
      final overflow = FlutterErrorDetails(
        exception: FlutterError('A RenderFlex overflowed by 10 pixels'),
        library: 'rendering library',
      );
      final other = FlutterErrorDetails(
        exception: StateError('boom'),
        library: 'my feature',
      );
      expect(AppErrorHandler.isFatalFlutterError(overflow), isFalse);
      expect(AppErrorHandler.isFatalFlutterError(other), isTrue);
    });

    test('reporter failures never escape', () async {
      AppErrorHandler.attachReporter(_ThrowingReporter());
      await AppErrorHandler.recordNonFatal(StateError('x'), null);
      AppErrorHandler.breadcrumb('still fine');
      await AppErrorHandler.setContext(city: 'Taichung');
    });

    test('breadcrumbs are sanitized and bounded', () {
      for (var i = 0; i < 50; i++) {
        AppErrorHandler.breadcrumb('step $i nick@example.com');
      }
      expect(AppErrorHandler.breadcrumbs, hasLength(30));
      expect(AppErrorHandler.breadcrumbs.last, contains('<email>'));
    });
  });

  group('AppPerformance without Firebase (QA B13)', () {
    test('measure still runs the action and returns its value', () async {
      final value = await AppPerformance.measure(
        traceName: AppTraces.busScheduleApi,
        action: () async => 42,
      );
      expect(value, 42);
    });

    test('measure propagates action errors unchanged', () async {
      expect(
        AppPerformance.measure<int>(
          traceName: AppTraces.busEtaApi,
          action: () async => throw const FormatException('bad'),
        ),
        throwsFormatException,
      );
    });
  });
}

class _ThrowingReporter implements ErrorReporter {
  @override
  Future<void> log(String message) => throw StateError('log');

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {required bool fatal, String? reason}) =>
      throw StateError('record');

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
          {required bool fatal}) =>
      throw StateError('flutter');

  @override
  Future<void> setCustomKey(String key, Object value) =>
      throw StateError('key');
}
