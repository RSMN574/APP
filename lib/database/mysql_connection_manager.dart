import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:synchronized/synchronized.dart';

import '../config/app_config.dart';

/// 判斷是否為應重連的連線失效錯誤（非 SQL 語法或資料錯誤）。
bool isTransientMysqlConnectionError(Object error) {
  if (error is TimeoutException || error is SocketException) {
    return true;
  }

  final msg = error.toString().toLowerCase();
  const needles = <String>[
    'connection closed',
    'connection lost',
    'lost connection',
    'socket closed',
    'socket',
    'timeout',
    'timed out',
    'server has gone away',
    'gone away',
    'not in connectionestablished',
    'not connected',
    'connection is not established',
    'connection reset',
    'broken pipe',
    "can't connect",
    'cannot connect',
    'network is unreachable',
    'software caused connection abort',
  ];
  return needles.any(msg.contains);
}

/// 統一管理 `mysql_client` 連線：connect / reconnect / idle disconnect / query retry。
class MySqlConnectionManager with WidgetsBindingObserver {
  MySqlConnectionManager._();

  static final MySqlConnectionManager instance = MySqlConnectionManager._();

  final Lock _lock = Lock();
  MySQLConnection? _conn;
  Timer? _idleTimer;
  bool _observerRegistered = false;
  bool _stale = false;

  static const Duration idleTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration queryTimeout = Duration(seconds: 20);
  static const Duration pingTimeout = Duration(seconds: 5);
  static const int defaultReconnectRetries = 2;

  MySQLConnection? get connection => _conn;

  bool get isConnected => _conn != null && _conn!.connected && !_stale;

  void _ensureLifecycleObserver() {
    if (_observerRegistered) return;
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _observerRegistered = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stale = true;
    } else if (state == AppLifecycleState.resumed) {
      _stale = true;
    }
  }

  Future<void> connect() {
    return _lock.synchronized(_connectUnlocked);
  }

  Future<void> disconnect() {
    return _lock.synchronized(_disconnectUnlocked);
  }

  Future<void> reconnect() {
    return _lock.synchronized(() async {
      await _disconnectUnlocked();
      await _connectUnlocked();
    });
  }

  Future<bool> checkConnection() async {
    final conn = _conn;
    if (conn == null || !conn.connected || _stale) return false;
    try {
      await conn.execute('SELECT 1').timeout(pingTimeout);
      return true;
    } catch (e) {
      debugPrint('Database connection check failed: $e');
      return false;
    }
  }

  Future<IResultSet> execute(
    String query, {
    List<dynamic>? params,
    int maxRetries = defaultReconnectRetries,
  }) {
    final convertedSql = _toNamedParams(query, params);
    final namedParams = _toNamedMap(params);
    final hasParams = namedParams != null && namedParams.isNotEmpty;
    final retries = maxRetries < 0 ? 0 : maxRetries;

    return _lock.synchronized(() async {
      Object? lastError;
      for (var attempt = 0; attempt <= retries; attempt++) {
        try {
          await _connectUnlocked();
          final conn = _conn;
          if (conn == null) {
            throw StateError('MySQL connection is not established');
          }

          final result = hasParams
              ? await conn
                  .execute(convertedSql, namedParams)
                  .timeout(queryTimeout)
              : await conn.execute(convertedSql).timeout(queryTimeout);

          _stale = false;
          _startIdleTimer();
          return result;
        } catch (e) {
          lastError = e;
          debugPrint(
            'MySQL query error (attempt ${attempt + 1}/${retries + 1}): $e',
          );

          if (!isTransientMysqlConnectionError(e) || attempt >= retries) {
            rethrow;
          }

          await _disconnectUnlocked();
        }
      }

      throw Exception(
        'Failed to execute query after ${retries + 1} attempts. Last error: $lastError',
      );
    });
  }

  Future<void> _connectUnlocked() async {
    _ensureLifecycleObserver();

    if (await _isUsableUnlocked()) return;

    await _disconnectUnlocked();
    AppConfig.requireDatabaseConfig();

    try {
      final conn = await MySQLConnection.createConnection(
        host: AppConfig.databaseHost,
        port: 3306,
        userName: AppConfig.databaseUser,
        password: AppConfig.databasePassword,
        databaseName: AppConfig.databaseName,
      );
      await conn.connect().timeout(connectTimeout);
      _conn = conn;
      _stale = false;
      _startIdleTimer();
    } catch (e, stack) {
      debugPrint('MySQL connection error: $e');
      debugPrintStack(stackTrace: stack);
      _conn = null;
      rethrow;
    }
  }

  Future<void> _disconnectUnlocked() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final conn = _conn;
    _conn = null;
    if (conn == null) return;
    try {
      await conn.close();
    } catch (e) {
      debugPrint('Error closing MySQL connection: $e');
    }
  }

  Future<bool> _isUsableUnlocked() async {
    if (_stale) return false;
    return checkConnection();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      disconnect();
    });
  }

  String _toNamedParams(String sql, List<dynamic>? params) {
    if (params == null || params.isEmpty) return sql;
    var index = 0;
    return sql.replaceAllMapped(RegExp(r'\?'), (match) => ':arg${index++}');
  }

  Map<String, dynamic>? _toNamedMap(List<dynamic>? params) {
    if (params == null || params.isEmpty) return null;
    final map = <String, dynamic>{};
    for (var i = 0; i < params.length; i++) {
      map['arg$i'] = params[i];
    }
    return map;
  }
}
