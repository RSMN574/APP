// lib/models/bike_prediction.dart
// 對應後端 /api/predict 回應結構

class BikePredictionResponse {
  final bool success;
  final BikePrediction? data;
  final PredictionMeta? meta;
  final String? errorMessage;

  BikePredictionResponse({
    required this.success,
    this.data,
    this.meta,
    this.errorMessage,
  });

  factory BikePredictionResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == true && json['data'] != null) {
      return BikePredictionResponse(
        success: true,
        data: BikePrediction.fromJson(json['data'] as Map<String, dynamic>),
        meta: json['meta'] != null
            ? PredictionMeta.fromJson(json['meta'] as Map<String, dynamic>)
            : null,
      );
    }
    return BikePredictionResponse(
      success: false,
      errorMessage: (json['error'] is Map)
          ? (json['error']['message']?.toString() ?? '預測失敗')
          : '預測失敗',
    );
  }
}

class PredictionMeta {
  final String? generatedAt;
  final int? lookbackDays;
  final int? historySamples;
  final int? elapsedMs;
  final bool cached;

  PredictionMeta({
    this.generatedAt,
    this.lookbackDays,
    this.historySamples,
    this.elapsedMs,
    this.cached = false,
  });

  factory PredictionMeta.fromJson(Map<String, dynamic> json) => PredictionMeta(
    generatedAt: json['generatedAt']?.toString(),
    lookbackDays: json['lookbackDays'] as int?,
    historySamples: json['historySamples'] as int?,
    elapsedMs: json['elapsedMs'] as int?,
    cached: json['cached'] == true,
  );
}

class BikePrediction {
  final String stationUID;
  final PredictionTarget target;
  final PredictionValues prediction;
  final PredictionConfidence confidence;
  final PredictionRisk risk;
  final PredictionDiagnostics diagnostics;
  final String summary;

  BikePrediction({
    required this.stationUID,
    required this.target,
    required this.prediction,
    required this.confidence,
    required this.risk,
    required this.diagnostics,
    required this.summary,
  });

  factory BikePrediction.fromJson(Map<String, dynamic> json) {
    return BikePrediction(
      stationUID: (json['station'] is Map)
          ? (json['station']['uid']?.toString() ?? '')
          : '',
      target: PredictionTarget.fromJson(json['target'] ?? {}),
      prediction: PredictionValues.fromJson(json['prediction'] ?? {}),
      confidence: PredictionConfidence.fromJson(json['confidence'] ?? {}),
      risk: PredictionRisk.fromJson(json['risk'] ?? {}),
      diagnostics: PredictionDiagnostics.fromJson(json['diagnostics'] ?? {}),
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class PredictionTarget {
  final String iso;
  final String local;
  final String weekday;
  final int hour;
  final int minute;

  PredictionTarget({
    required this.iso,
    required this.local,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  factory PredictionTarget.fromJson(Map<String, dynamic> json) => PredictionTarget(
    iso: json['iso']?.toString() ?? '',
    local: json['local']?.toString() ?? '',
    weekday: json['weekday']?.toString() ?? '',
    hour: (json['hour'] as num?)?.toInt() ?? 0,
    minute: (json['minute'] as num?)?.toInt() ?? 0,
  );
}

class PredictionValues {
  final int availableRentBikes;
  final int availableReturnBikes;
  final int generalBikes;
  final int electricBikes;
  final int totalSlots;
  final List<int> rentCIRange;
  final List<int> returnCIRange;

  PredictionValues({
    required this.availableRentBikes,
    required this.availableReturnBikes,
    required this.generalBikes,
    required this.electricBikes,
    required this.totalSlots,
    required this.rentCIRange,
    required this.returnCIRange,
  });

  factory PredictionValues.fromJson(Map<String, dynamic> json) {
    List<int> toIntList(dynamic v) =>
        (v is List) ? v.map((e) => (e as num).toInt()).toList() : <int>[];

    return PredictionValues(
      availableRentBikes: (json['availableRentBikes'] as num?)?.toInt() ?? 0,
      availableReturnBikes: (json['availableReturnBikes'] as num?)?.toInt() ?? 0,
      generalBikes: (json['generalBikes'] as num?)?.toInt() ?? 0,
      electricBikes: (json['electricBikes'] as num?)?.toInt() ?? 0,
      totalSlots: (json['totalSlots'] as num?)?.toInt() ?? 0,
      rentCIRange: toIntList(json['rentCIRange']),
      returnCIRange: toIntList(json['returnCIRange']),
    );
  }
}

class PredictionConfidence {
  final String level; // high / medium / low
  final String label; // 高 / 中 / 低
  final int sampleCount;

  PredictionConfidence({
    required this.level,
    required this.label,
    required this.sampleCount,
  });

  factory PredictionConfidence.fromJson(Map<String, dynamic> json) => PredictionConfidence(
    level: json['level']?.toString() ?? 'low',
    label: json['label']?.toString() ?? '低',
    sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
  );
}

class PredictionRisk {
  final String level; // high / medium / low
  final double rentRatio;
  final double returnRatio;
  final List<String> alerts;

  PredictionRisk({
    required this.level,
    required this.rentRatio,
    required this.returnRatio,
    required this.alerts,
  });

  factory PredictionRisk.fromJson(Map<String, dynamic> json) => PredictionRisk(
    level: json['level']?.toString() ?? 'low',
    rentRatio: (json['rentRatio'] as num?)?.toDouble() ?? 0,
    returnRatio: (json['returnRatio'] as num?)?.toDouble() ?? 0,
    alerts: (json['alerts'] is List)
        ? (json['alerts'] as List).map((e) => e.toString()).toList()
        : <String>[],
  );
}

class PredictionDiagnostics {
  final int sampleCount;
  final int windowMinutes;
  final double movingAvgRent;
  final double movingAvgReturn;
  final bool trendUsed;

  PredictionDiagnostics({
    required this.sampleCount,
    required this.windowMinutes,
    required this.movingAvgRent,
    required this.movingAvgReturn,
    required this.trendUsed,
  });

  factory PredictionDiagnostics.fromJson(Map<String, dynamic> json) => PredictionDiagnostics(
    sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
    windowMinutes: (json['windowMinutes'] as num?)?.toInt() ?? 0,
    movingAvgRent: (json['movingAvgRent'] as num?)?.toDouble() ?? 0,
    movingAvgReturn: (json['movingAvgReturn'] as num?)?.toDouble() ?? 0,
    trendUsed: json['trendUsed'] == true,
  );
}