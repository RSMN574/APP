import 'package:cloud_firestore/cloud_firestore.dart';

enum RailTrafficType { tra, hsr }

class RailMileageRecord {
  const RailMileageRecord({
    required this.id,
    required this.operator,
    required this.origin,
    required this.destination,
    required this.trainNo,
    required this.distanceKm,
    required this.rawQr,
    required this.createdAt,
    this.note,
  });

  final String id;
  final RailTrafficType operator;
  final String origin;
  final String destination;
  final String trainNo;
  final double distanceKm;
  final String rawQr;
  final DateTime createdAt;
  final String? note;

  factory RailMileageRecord.fromMap(Map<String, dynamic> map, {String? overrideId}) {
    final createdAtValue = map['createdAt'];
    final createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : DateTime.tryParse(createdAtValue?.toString() ?? '') ?? DateTime.now();

    return RailMileageRecord(
      id: overrideId ?? map['id']?.toString() ?? createdAt.millisecondsSinceEpoch.toString(),
      operator: (map['operator']?.toString() == 'hsr')
          ? RailTrafficType.hsr
          : RailTrafficType.tra,
      origin: (map['origin'] ?? '').toString(),
      destination: (map['destination'] ?? '').toString(),
      trainNo: (map['trainNo'] ?? '').toString(),
      distanceKm: (map['distanceKm'] is num)
          ? (map['distanceKm'] as num).toDouble()
          : double.tryParse(map['distanceKm']?.toString() ?? '') ?? 0.0,
      rawQr: (map['rawQr'] ?? '').toString(),
      createdAt: createdAt,
      note: map['note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operator': operator.name,
      'origin': origin,
      'destination': destination,
      'trainNo': trainNo,
      'distanceKm': distanceKm,
      'rawQr': rawQr,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }
}
