import 'dart:convert';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

/// 站牌到站時間的顯示結果（純資料，不依賴 BuildContext）。
class StopArrival {
  final String displayTime; // 「即將進站」、「3 分鐘」、時間字串
  final String colorKey; // '0' / '2' / 'min' / '' / l10n.text_317
  final String plateNumb;
  final String estimatesJson;
  final String stopPosition;
  final String stopId;

  /// 是否為「有即時資料可自動更新」的狀態（由 formatter 判斷）。
  final bool hasLiveData;

  const StopArrival({
    required this.displayTime,
    required this.colorKey,
    required this.plateNumb,
    required this.estimatesJson,
    required this.stopPosition,
    required this.stopId,
    required this.hasLiveData,
  });
}

class BusStopTimeFormatter {
  const BusStopTimeFormatter._();

  static StopArrival format({
    required Map<String, dynamic>? stopTime,
    required AppLocalizations l10n,
    required DateTime now,
  }) {
    if (stopTime == null) {
      return StopArrival(
        displayTime: l10n.text_339,
        colorKey: l10n.text_317,
        plateNumb: '',
        estimatesJson: '',
        stopPosition: '',
        stopId: '',
        hasLiveData: false,
      );
    }

    // ✅ P3：統一從 `Estimates` 收集車牌（原本只在 bus_stop_info_service 有）。
    final plateList = _collectPlateNumbers(stopTime);
    final plate = plateList.isNotEmpty
        ? plateList.toString()
        : (stopTime['PlateNumb'] ?? '').toString();

    final estimates = (stopTime['Estimates'] ?? '').toString();
    final stopId = (stopTime['StopID'] ?? '').toString();
    final stopPosition = stopTime['StopPosition']?.toString() ?? '';

    // 1) EstimateTime（秒）
    final estimateRaw = stopTime['EstimateTime'];
    if (estimateRaw is num) {
      final minutes = (estimateRaw / 60).floor();
      if (estimateRaw == 0 || minutes < 1) {
        return StopArrival(
          displayTime: l10n.text_316,
          colorKey: '0',
          plateNumb: plate,
          estimatesJson: estimates,
          stopPosition: stopPosition,
          stopId: stopId,
          hasLiveData: true,
        );
      }
      if (minutes < 3) {
        return StopArrival(
          displayTime: l10n.nearStopMinutes(minutes.toString()),
          colorKey: '2',
          plateNumb: plate,
          estimatesJson: estimates,
          stopPosition: stopPosition,
          stopId: stopId,
          hasLiveData: true,
        );
      }
      return StopArrival(
        displayTime: l10n.nearStopMinutes(minutes.toString()),
        colorKey: 'min',
        plateNumb: '',
        estimatesJson: estimates,
        stopPosition: stopPosition,
        stopId: stopId,
        hasLiveData: true,
      );
    }

    // 2) NextBusTime（下次發車時間）
    final nextRaw = stopTime['NextBusTime'];
    if (nextRaw is String && nextRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(nextRaw)?.toLocal();
      if (parsed != null) {
        final totalMinutes = parsed.difference(now).inMinutes;
        if (totalMinutes < 0) {
          return StopArrival(
            displayTime: totalMinutes > -5 ? l10n.text_340 : l10n.text_317,
            colorKey: l10n.text_317,
            plateNumb: '',
            estimatesJson: estimates,
            stopPosition: stopPosition,
            stopId: stopId,
            hasLiveData: false,
          );
        }
        if (totalMinutes < 60) {
          if (totalMinutes < 1) {
            return StopArrival(
              displayTime: l10n.text_316,
              colorKey: '0',
              plateNumb: plate,
              estimatesJson: estimates,
              stopPosition: stopPosition,
              stopId: stopId,
              hasLiveData: true,
            );
          }
          if (totalMinutes < 3) {
            return StopArrival(
              displayTime: '$totalMinutes 分鐘',
              colorKey: '2',
              plateNumb: plate,
              estimatesJson: estimates,
              stopPosition: stopPosition,
              stopId: stopId,
              hasLiveData: true,
            );
          }
          return StopArrival(
            displayTime: l10n.nearStopMinutes(totalMinutes.toString()),
            colorKey: 'min',
            plateNumb: '',
            estimatesJson: estimates,
            stopPosition: stopPosition,
            stopId: stopId,
            hasLiveData: true,
          );
        }
        final hh = parsed.hour.toString().padLeft(2, '0');
        final mm = parsed.minute.toString().padLeft(2, '0');
        return StopArrival(
          displayTime: '$hh:$mm',
          // ✅ P3：原本是 ''，改為 l10n.text_317，與 bus_stop_info 一致。
          colorKey: l10n.text_317,
          plateNumb: '',
          estimatesJson: estimates,
          stopPosition: stopPosition,
          stopId: stopId,
          hasLiveData: true,
        );
      }
    }

    // 3) 無資料
    return StopArrival(
      displayTime: l10n.text_317,
      colorKey: l10n.text_317,
      plateNumb: '',
      estimatesJson: estimates,
      stopPosition: stopPosition,
      stopId: stopId,
      hasLiveData: false,
    );
  }

  /// 從 `stopTime['Estimates']` 收集車牌清單。
  ///
  /// 支援：
  /// - `List<Map>` 形式（原始 API）
  /// - JSON 字串形式（DB 還原）
  /// - 空字串或缺失時回傳空清單
  static List<String> _collectPlateNumbers(Map<String, dynamic> stopTime) {
    final raw = stopTime['Estimates'];
    dynamic decoded = raw;

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == 'null') return const [];
      try {
        decoded = json.decode(trimmed);
      } catch (_) {
        return const [];
      }
    }

    if (decoded is! List) return const [];

    final out = <String>[];
    for (final e in decoded) {
      if (e is Map && e['PlateNumb'] != null) {
        final plate = e['PlateNumb'].toString();
        if (plate.isNotEmpty) out.add(plate);
      }
    }
    return out;
  }
}