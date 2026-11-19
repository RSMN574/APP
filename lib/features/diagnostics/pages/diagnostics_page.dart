import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bus/state/bus_schedule_provider.dart';
import '../../../core/error/app_error_handler.dart';
import '../../../core/startup/startup_metrics.dart';

/// 診斷入口是否可用。
///
/// 只在 Debug build，或以 `--dart-define=QA_DIAGNOSTICS=true` 明確建置的
/// 內部測試版開啟；發給一般測試者的 Beta APK 不帶此參數，入口完全不會出現。
class AppDiagnostics {
  AppDiagnostics._();

  static const bool _qaFlag =
      bool.fromEnvironment('QA_DIAGNOSTICS', defaultValue: false);

  static bool get enabled => kDebugMode || _qaFlag;
}

/// Crashlytics / 效能 / 快取診斷頁（僅限 [AppDiagnostics.enabled]）。
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String _status = '';

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Future<void> _run(String label, Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _status = '$label：已送出');
    } catch (e) {
      if (mounted) setState(() => _status = '$label 失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppDiagnostics.enabled) {
      // 防禦：即使被以路由名稱開啟，正式版也不提供任何功能。
      return const Scaffold(body: SizedBox.shrink());
    }
    final repo = BusScheduleProvider.sharedRepository;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('QA 診斷（內部測試）')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Firebase：${_firebaseReady ? '已初始化' : '未初始化'}'),
          if (_firebaseReady)
            Text('Crashlytics 收集：'
                '${FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled}'),
          const Divider(),
          FilledButton.tonal(
            onPressed: () => _run('非致命錯誤', () async {
              AppErrorHandler.breadcrumb('qa: before non-fatal test');
              await AppErrorHandler.recordNonFatal(
                StateError(
                    'QA non-fatal test ${DateTime.now().toIso8601String()}'),
                StackTrace.current,
                feature: 'qa_diagnostics',
                reason: 'manual_test',
              );
              if (_firebaseReady) {
                await FirebaseCrashlytics.instance.sendUnsentReports();
              }
            }),
            child: const Text('送出測試用非致命錯誤'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              AppErrorHandler.breadcrumb('qa: before flutter error test');
              FlutterError.reportError(FlutterErrorDetails(
                exception: StateError('QA FlutterError test'),
                stack: StackTrace.current,
                library: 'qa diagnostics',
              ));
              setState(() => _status = 'FlutterError：已送出');
            },
            child: const Text('觸發 FlutterError（fatal 分類）'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: !_firebaseReady
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('確定要讓 App 閃退？'),
                        content:
                            const Text('用於驗證 Crashlytics。重新開啟 App 後報告才會上傳。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('閃退'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      AppErrorHandler.breadcrumb('qa: forced crash');
                      FirebaseCrashlytics.instance.crash();
                    }
                  },
            child: const Text('測試用 Crash（原生閃退）'),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_status, style: theme.textTheme.bodyMedium),
          ],
          const Divider(height: 32),
          Text('啟動量測', style: theme.textTheme.titleMedium),
          for (final e in StartupMetrics.marks.entries)
            Text('${e.key}: ${e.value} ms'),
          for (final e in StartupMetrics.durations.entries)
            Text('${e.key}: ${e.value} ms'),
          const Divider(height: 32),
          Text('班表快取', style: theme.textTheme.titleMedium),
          Text('hits=${repo.cacheHits} misses=${repo.cacheMisses} '
              'network=${repo.networkRequests}'),
          const Divider(height: 32),
          Text('Breadcrumbs', style: theme.textTheme.titleMedium),
          for (final b in AppErrorHandler.breadcrumbs.reversed)
            Text(b, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
