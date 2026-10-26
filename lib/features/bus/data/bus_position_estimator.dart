import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One GPS sample from the vehicle data source.
class BusGpsSample {
  const BusGpsSample({
    required this.position,
    required this.speedKmh,
    required this.recordedAt,
    this.headingDegrees,
  });

  final LatLng position;

  /// Speed in km/h, as returned/normalized by the caller.
  final double speedKmh;

  /// Timestamp associated with the GPS sample, not the time the UI received it.
  final DateTime recordedAt;

  /// Optional bearing in degrees clockwise from north.
  final double? headingDegrees;
}

class BusPositionEstimate {
  const BusPositionEstimate({
    required this.position,
    required this.isEstimated,
    required this.age,
    required this.distanceAlongRouteMeters,
    required this.reason,
  });

  final LatLng position;
  final bool isEstimated;
  final Duration age;
  final double distanceAlongRouteMeters;
  final String reason;
}

/// Estimates a short-horizon bus position along the route shape.
///
/// Safety properties:
/// - Never extrapolates beyond [maxExtrapolation].
/// - Rejects implausible speed and invalid coordinates.
/// - Uses the closest route segment, with heading as a tie-breaker.
/// - If route geometry or sample time is unavailable, callers should display
///   the raw GPS point instead of inventing a predicted location.
/// - The route points must be ordered in the vehicle's travel direction.
class BusPositionEstimator {
  const BusPositionEstimator({
    this.maxExtrapolation = const Duration(seconds: 15),
    this.maxAcceptedGpsAge = const Duration(seconds: 30),
    this.maxSpeedKmh = 100,
    this.minSpeedKmh = 0,
    this.headingPenaltyMeters = 45,
  });

  final Duration maxExtrapolation;
  final Duration maxAcceptedGpsAge;
  final double maxSpeedKmh;
  final double minSpeedKmh;
  final double headingPenaltyMeters;

  BusPositionEstimate? estimate({
    required BusGpsSample sample,
    required DateTime now,
    required List<LatLng> routePoints,
  }) {
    if (!_validCoordinate(sample.position)) return null;

    final ageMs = now.difference(sample.recordedAt).inMilliseconds;
    if (ageMs < -5000) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: Duration.zero,
        distanceAlongRouteMeters: 0,
        reason: 'GPS timestamp is in the future; showing raw GPS',
      );
    }

    final age = Duration(milliseconds: ageMs < 0 ? 0 : ageMs);
    if (age > maxAcceptedGpsAge) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: age,
        distanceAlongRouteMeters: 0,
        reason: 'GPS data is stale; showing raw GPS',
      );
    }

    if (routePoints.length < 2 ||
        !_validCoordinate(routePoints.first) ||
        !_validCoordinate(routePoints.last)) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: age,
        distanceAlongRouteMeters: 0,
        reason: 'Route geometry unavailable; showing raw GPS',
      );
    }

    final speed = sample.speedKmh;
    if (!speed.isFinite || speed < minSpeedKmh || speed > maxSpeedKmh) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: age,
        distanceAlongRouteMeters: 0,
        reason: 'Speed is missing or implausible; showing raw GPS',
      );
    }

    final projection = _projectOntoRoute(
      sample.position,
      routePoints,
      sample.headingDegrees,
    );
    if (projection == null) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: age,
        distanceAlongRouteMeters: 0,
        reason: 'Could not match GPS to route; showing raw GPS',
      );
    }

    final extrapolationSeconds =
        (age.inMilliseconds / 1000).clamp(0.0, maxExtrapolation.inMilliseconds / 1000).toDouble();
    final travelMeters = speed / 3.6 * extrapolationSeconds;
    final targetDistance = (projection.distanceAlongMeters + travelMeters)
        .clamp(0.0, projection.totalRouteMeters).toDouble();
    final predicted = _pointAtDistance(routePoints, targetDistance);

    if (predicted == null || !_validCoordinate(predicted)) {
      return BusPositionEstimate(
        position: sample.position,
        isEstimated: false,
        age: age,
        distanceAlongRouteMeters: projection.distanceAlongMeters,
        reason: 'Could not interpolate route position; showing raw GPS',
      );
    }

    final shouldPredict = extrapolationSeconds >= 1 && travelMeters >= 2;
    return BusPositionEstimate(
      position: shouldPredict ? predicted : projection.point,
      isEstimated: shouldPredict,
      age: age,
      distanceAlongRouteMeters: targetDistance,
      reason: shouldPredict
          ? 'Short-horizon estimate constrained to route geometry'
          : 'GPS is recent; showing route-matched position',
    );
  }

  _RouteProjection? _projectOntoRoute(
    LatLng gps,
    List<LatLng> points,
    double? heading,
  ) {
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(
        cumulative.last + _distanceMeters(points[i - 1], points[i]),
      );
    }

    final total = cumulative.last;
    if (total <= 0) return null;

    _RouteProjection? best;
    var bestScore = double.infinity;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final projected = _projectPointToSegment(gps, a, b);
      final segmentDistance = _distanceMeters(gps, projected.point);
      final segmentBearing = _bearingDegrees(a, b);
      final headingDifference = heading == null
          ? 0.0
          : _angularDifference(heading, segmentBearing);
      final score = segmentDistance +
          (heading == null ? 0 : headingDifference / 180 * headingPenaltyMeters);

      if (score < bestScore) {
        final segmentLength = _distanceMeters(a, b);
        bestScore = score;
        best = _RouteProjection(
          point: projected.point,
          distanceAlongMeters:
              cumulative[i] + segmentLength * projected.t,
          totalRouteMeters: total,
        );
      }
    }

    // If GPS is far away from the route shape, don't snap it onto a distant road.
    if (best == null ||
        _distanceMeters(gps, best.point) > 150) {
      return null;
    }
    return best;
  }

  LatLng? _pointAtDistance(List<LatLng> points, double targetMeters) {
    if (points.isEmpty) return null;
    if (targetMeters <= 0) return points.first;

    var travelled = 0.0;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final segmentLength = _distanceMeters(start, end);
      if (segmentLength <= 0) continue;

      if (travelled + segmentLength >= targetMeters) {
        final t = ((targetMeters - travelled) / segmentLength).clamp(0.0, 1.0);
        return LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        );
      }
      travelled += segmentLength;
    }
    return points.last;
  }

  _SegmentProjection _projectPointToSegment(
    LatLng point,
    LatLng start,
    LatLng end,
  ) {
    // Local equirectangular projection; suitable for short city bus segments.
    final meanLat = (start.latitude + end.latitude + point.latitude) / 3;
    final cosLat = math.cos(meanLat * math.pi / 180);
    final ax = 0.0;
    final ay = 0.0;
    final bx = _longitudeMeters(end.longitude - start.longitude, cosLat);
    final by = _latitudeMeters(end.latitude - start.latitude);
    final px = _longitudeMeters(point.longitude - start.longitude, cosLat);
    final py = _latitudeMeters(point.latitude - start.latitude);

    final dx = bx - ax;
    final dy = by - ay;
    final denominator = dx * dx + dy * dy;
    final t = denominator == 0
        ? 0.0
        : ((px * dx + py * dy) / denominator).clamp(0.0, 1.0).toDouble();

    return _SegmentProjection(
      point: LatLng(
        start.latitude + (end.latitude - start.latitude) * t,
        start.longitude + (end.longitude - start.longitude) * t,
      ),
      t: t,
    );
  }

  bool _validCoordinate(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  double _latitudeMeters(double deltaDegrees) =>
      deltaDegrees * math.pi / 180 * 6371000.0;

  double _longitudeMeters(double deltaDegrees, double cosLatitude) =>
      deltaDegrees * math.pi / 180 * 6371000.0 * cosLatitude;

  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _angularDifference(double a, double b) {
    final difference = ((a - b) % 360).abs();
    return difference > 180 ? 360 - difference : difference;
  }
}

class _RouteProjection {
  const _RouteProjection({
    required this.point,
    required this.distanceAlongMeters,
    required this.totalRouteMeters,
  });

  final LatLng point;
  final double distanceAlongMeters;
  final double totalRouteMeters;
}

class _SegmentProjection {
  const _SegmentProjection({required this.point, required this.t});

  final LatLng point;
  final double t;
}
