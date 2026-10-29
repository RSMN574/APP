/// 單一車次的座位狀態。
class HsrSeatStatus {
  const HsrSeatStatus({
    required this.trainNo,
    required this.direction,
    required this.originStationId,
    required this.destinationStationId,
    required this.standardSeatStatus,
    required this.businessSeatStatus,
  });

  final String trainNo;
  final int direction;
  final String originStationId;
  final String destinationStationId;

  /// "O" = 有座位、"X" = 無座位、"" = 未知
  final String standardSeatStatus;
  final String businessSeatStatus;

  bool get hasStandardSeat => standardSeatStatus == 'O';
  bool get hasBusinessSeat => businessSeatStatus == 'O';
  bool get isUnknown =>
      standardSeatStatus.isEmpty && businessSeatStatus.isEmpty;

  factory HsrSeatStatus.fromJson(Map<String, dynamic> json) {
    return HsrSeatStatus(
      trainNo: (json['TrainNo'] ?? '').toString(),
      direction: (json['Direction'] is int)
          ? json['Direction'] as int
          : int.tryParse('${json['Direction']}') ?? 0,
      originStationId: (json['OriginStationID'] ?? '').toString(),
      destinationStationId:
      (json['DestinationStationID'] ?? '').toString(),
      standardSeatStatus:
      (json['StandardSeatStatus'] ?? '').toString().toUpperCase(),
      businessSeatStatus:
      (json['BusinessSeatStatus'] ?? '').toString().toUpperCase(),
    );
  }
}

/// 一次 OD 查詢的完整座位資料。
class HsrOdSeatStatus {
  const HsrOdSeatStatus({
    required this.updateTime,
    required this.trainDate,
    required this.byTrainNo,
  });

  final DateTime updateTime;
  final String trainDate;

  /// TrainNo → HsrSeatStatus
  final Map<String, HsrSeatStatus> byTrainNo;

  HsrSeatStatus? forTrain(String trainNo) => byTrainNo[trainNo];

  bool get isEmpty => byTrainNo.isEmpty;

  static HsrOdSeatStatus empty() => HsrOdSeatStatus(
    updateTime: DateTime.now(),
    trainDate: '',
    byTrainNo: const {},
  );

  factory HsrOdSeatStatus.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['AvailableSeats'] as List<dynamic>?) ?? const [];
    final byTrainNo = <String, HsrSeatStatus>{};
    for (final e in rawList) {
      if (e is! Map) continue;
      final status = HsrSeatStatus.fromJson(Map<String, dynamic>.from(e));
      if (status.trainNo.isEmpty) continue;
      byTrainNo[status.trainNo] = status;
    }

    DateTime updateTime;
    try {
      updateTime = DateTime.parse(
        (json['UpdateTime'] ?? '').toString(),
      ).toLocal();
    } catch (_) {
      updateTime = DateTime.now();
    }

    return HsrOdSeatStatus(
      updateTime: updateTime,
      trainDate: (json['TrainDate'] ?? '').toString(),
      byTrainNo: byTrainNo,
    );
  }
}