import 'package:cloud_firestore/cloud_firestore.dart';

class FlightMileageRecord {
  const FlightMileageRecord({
    required this.id,
    required this.airline,
    required this.flightNo,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.travelDate,
    required this.distanceKm,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String airline;
  final String flightNo;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime travelDate;
  final double distanceKm;
  final String note;
  final DateTime createdAt;

  factory FlightMileageRecord.fromMap(Map<String, dynamic> map, {String? overrideId}) {
    final createdValue = map['createdAt'];
    final travelValue = map['travelDate'];
    return FlightMileageRecord(
      id: overrideId ?? map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      airline: (map['airline'] ?? '').toString(),
      flightNo: (map['flightNo'] ?? '').toString(),
      departureAirport: (map['departureAirport'] ?? '').toString(),
      arrivalAirport: (map['arrivalAirport'] ?? '').toString(),
      travelDate: travelValue is Timestamp
          ? travelValue.toDate()
          : DateTime.tryParse(travelValue?.toString() ?? '') ?? DateTime.now(),
      distanceKm: (map['distanceKm'] is num)
          ? (map['distanceKm'] as num).toDouble()
          : double.tryParse(map['distanceKm']?.toString() ?? '') ?? 0.0,
      note: (map['note'] ?? '').toString(),
      createdAt: createdValue is Timestamp
          ? createdValue.toDate()
          : DateTime.tryParse(createdValue?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'airline': airline,
      'flightNo': flightNo,
      'departureAirport': departureAirport,
      'arrivalAirport': arrivalAirport,
      'travelDate': Timestamp.fromDate(travelDate),
      'distanceKm': distanceKm,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
