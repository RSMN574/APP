import 'dart:ui' show Locale;

String? _str(Object? v) => (v is String && v.isNotEmpty) ? v : null;

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) {
  if (v is! List) return <T>[];
  return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList(growable: false);
}

List<String> _strings(Object? v) =>
    v is List ? v.whereType<String>().toList(growable: false) : const <String>[];

/// 中英文名稱。缺哪個語言就退回另一個，兩者都沒有才回傳空字串。
class LocalizedText {
  const LocalizedText({this.zh, this.en});
  final String? zh;
  final String? en;

  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) return LocalizedText(zh: _str(json['zh']), en: _str(json['en']));
    return const LocalizedText();
  }

  String resolve(Locale locale) {
    final preferEn = locale.languageCode == 'en';
    final first = preferEn ? en : zh;
    final second = preferEn ? zh : en;
    return first ?? second ?? '';
  }

  bool get isEmpty => zh == null && en == null;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lon);
  final double lat;
  final double lon;
}

class SystemCoverage {
  const SystemCoverage({required this.shape, required this.facilityStations, required this.transferStations});
  final bool shape;
  final int facilityStations;
  final int transferStations;

  factory SystemCoverage.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return SystemCoverage(
      shape: m['shape'] == true,
      facilityStations: (m['facilityStations'] as num?)?.toInt() ?? 0,
      transferStations: (m['transferStations'] as num?)?.toInt() ?? 0,
    );
  }
}

class MetroSystem {
  const MetroSystem({
    required this.code,
    required this.name,
    required this.cityCodes,
    required this.lineUids,
    required this.stationCount,
    required this.coverage,
  });
  final String code;
  final LocalizedText name;
  final List<String> cityCodes;
  final List<String> lineUids;
  final int stationCount;
  final SystemCoverage coverage;

  factory MetroSystem.fromJson(Map<String, dynamic> j) => MetroSystem(
        code: j['code'] as String,
        name: LocalizedText.fromJson(j['name']),
        cityCodes: _strings(j['cityCodes']),
        lineUids: _strings(j['lineUids']),
        stationCount: (j['stationCount'] as num?)?.toInt() ?? 0,
        coverage: SystemCoverage.fromJson(j['coverage']),
      );
}

class MetroLine {
  const MetroLine({
    required this.uid,
    required this.operator,
    required this.id,
    required this.name,
    required this.colorArgb,
    required this.stationUids,
    required this.edges,
    required this.hasShape,
  });
  final String uid;
  final String operator;
  final String id;
  final LocalizedText name;

  /// 後端只在有確定色碼時提供，否則為 null，由 UI 決定後備色。
  final int? colorArgb;
  final List<String> stationUids;
  final List<List<String>> edges;
  final bool hasShape;

  factory MetroLine.fromJson(Map<String, dynamic> j) {
    final hex = _str(j['color']);
    final rgb = hex == null ? null : int.tryParse(hex, radix: 16);
    return MetroLine(
      uid: j['uid'] as String,
      operator: j['operator'] as String,
      id: j['id'] as String,
      name: LocalizedText.fromJson(j['name']),
      colorArgb: rgb == null ? null : (0xFF000000 | rgb),
      stationUids: _strings(j['stationUids']),
      edges: (j['edges'] is List)
          ? (j['edges'] as List)
              .whereType<List>()
              .map((e) => e.whereType<String>().toList(growable: false))
              .where((e) => e.length == 2)
              .toList(growable: false)
          : const <List<String>>[],
      hasShape: j['hasShape'] == true,
    );
  }
}

class MetroStation {
  const MetroStation({
    required this.uid,
    required this.operator,
    required this.code,
    required this.name,
    required this.lat,
    required this.lon,
    required this.address,
    required this.lineUids,
  });
  final String uid;
  final String operator;
  final String code;
  final LocalizedText name;
  final double? lat;
  final double? lon;
  final String? address;
  final List<String> lineUids;

  bool get hasPosition => lat != null && lon != null;

  factory MetroStation.fromJson(Map<String, dynamic> j) => MetroStation(
        uid: j['uid'] as String,
        operator: j['operator'] as String,
        code: j['code'] as String,
        name: LocalizedText.fromJson(j['name']),
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        address: _str(j['address']),
        lineUids: _strings(j['lineUids']),
      );
}

/// 兩個車站之間的轉乘連結。kind: same_system / cross_system；source: sql（資料明列）/ derived（由座標與站名推導）。
class StationLink {
  const StationLink({
    required this.a,
    required this.b,
    required this.kind,
    required this.source,
    this.description,
    this.isOnSite,
    this.distanceM,
    this.floor,
  });
  final String a;
  final String b;
  final String kind;
  final String source;
  final String? description;
  final bool? isOnSite;
  final int? distanceM;
  final String? floor;

  bool get isCrossSystem => kind == 'cross_system';
  bool get isDerived => source == 'derived';
  String other(String uid) => uid == a ? b : a;

  factory StationLink.fromJson(Map<String, dynamic> j) => StationLink(
        a: j['a'] as String,
        b: j['b'] as String,
        kind: (j['kind'] as String?) ?? 'same_system',
        source: (j['source'] as String?) ?? 'sql',
        description: _str(j['description']),
        isOnSite: j['isOnSite'] as bool?,
        distanceM: (j['distanceM'] as num?)?.toInt(),
        floor: _str(j['floor']),
      );
}

class MetroCatalog {
  MetroCatalog({
    required this.version,
    required this.systems,
    required this.lines,
    required this.stations,
    required this.links,
  })  : stationByUid = {for (final s in stations) s.uid: s},
        lineByUid = {for (final l in lines) l.uid: l},
        systemByCode = {for (final s in systems) s.code: s},
        _linksByStation = _indexLinks(links);

  final String version;
  final List<MetroSystem> systems;
  final List<MetroLine> lines;
  final List<MetroStation> stations;
  final List<StationLink> links;
  final Map<String, MetroStation> stationByUid;
  final Map<String, MetroLine> lineByUid;
  final Map<String, MetroSystem> systemByCode;
  final Map<String, List<StationLink>> _linksByStation;

  List<StationLink> linksOf(String uid) => _linksByStation[uid] ?? const <StationLink>[];

  static Map<String, List<StationLink>> _indexLinks(List<StationLink> links) {
    final m = <String, List<StationLink>>{};
    for (final l in links) {
      m.putIfAbsent(l.a, () => []).add(l);
      m.putIfAbsent(l.b, () => []).add(l);
    }
    return m;
  }

  factory MetroCatalog.fromJson(Map<String, dynamic> j) => MetroCatalog(
        version: (j['version'] as String?) ?? '',
        systems: _list(j['systems'], MetroSystem.fromJson),
        lines: _list(j['lines'], MetroLine.fromJson),
        stations: _list(j['stations'], MetroStation.fromJson),
        links: _list(j['links'], StationLink.fromJson),
      );
}

/// 一條路線的幾何。segments 內座標已轉為 (緯度, 經度)；各段不保證相連，必須逐段繪製。
class LineShape {
  const LineShape({required this.lineUid, required this.segments});
  final String lineUid;
  final List<List<GeoPoint>> segments;

  factory LineShape.fromJson(Map<String, dynamic> j) {
    final segs = <List<GeoPoint>>[];
    final raw = j['segments'];
    if (raw is List) {
      for (final seg in raw) {
        if (seg is! List) continue;
        final pts = <GeoPoint>[];
        for (final p in seg) {
          // 後端為 [經度, 緯度]
          if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
            pts.add(GeoPoint((p[1] as num).toDouble(), (p[0] as num).toDouble()));
          }
        }
        if (pts.length >= 2) segs.add(pts);
      }
    }
    return LineShape(lineUid: j['lineUid'] as String, segments: segs);
  }
}

// ---------------- 車站詳情 ----------------

class FacilityEntry {
  const FacilityEntry({this.floor, this.description});
  final String? floor;
  final String? description;
  factory FacilityEntry.fromJson(Map<String, dynamic> j) =>
      FacilityEntry(floor: _str(j['floor']), description: _str(j['description']));
}

class MapLink {
  const MapLink({required this.url, required this.name, this.floor});
  final String url;
  final LocalizedText name;
  final String? floor;
  static MapLink? tryParse(Map<String, dynamic> j) {
    final url = _str(j['url']);
    if (url == null) return null;
    return MapLink(url: url, name: LocalizedText.fromJson(j['name']), floor: _str(j['floor']));
  }
}

class StationFacilities {
  const StationFacilities({
    required this.elevators,
    required this.infoSpots,
    required this.drinkingFountains,
    required this.toilets,
    required this.maps,
  });
  final List<FacilityEntry> elevators;
  final List<FacilityEntry> infoSpots;
  final List<FacilityEntry> drinkingFountains;
  final List<FacilityEntry> toilets;
  final List<MapLink> maps;

  bool get isEmpty =>
      elevators.isEmpty && infoSpots.isEmpty && drinkingFountains.isEmpty && toilets.isEmpty && maps.isEmpty;

  factory StationFacilities.fromJson(Map<String, dynamic> j) => StationFacilities(
        elevators: _list(j['elevators'], FacilityEntry.fromJson),
        infoSpots: _list(j['infoSpots'], FacilityEntry.fromJson),
        drinkingFountains: _list(j['drinkingFountains'], FacilityEntry.fromJson),
        toilets: _list(j['toilets'], FacilityEntry.fromJson),
        maps: _list<MapLink?>(j['maps'], MapLink.tryParse).whereType<MapLink>().toList(growable: false),
      );
}

class AccessEntry {
  const AccessEntry({
    this.operatorCode,
    required this.operatorName,
    required this.stationName,
    this.floor,
    this.description,
    this.isOnSite,
  });
  final String? operatorCode;
  final LocalizedText operatorName;
  final LocalizedText stationName;
  final String? floor;
  final String? description;
  final bool? isOnSite;
  factory AccessEntry.fromJson(Map<String, dynamic> j) => AccessEntry(
        operatorCode: _str(j['operatorCode']),
        operatorName: LocalizedText.fromJson(j['operatorName']),
        stationName: LocalizedText.fromJson(j['stationName']),
        floor: _str(j['floor']),
        description: _str(j['description']),
        isOnSite: j['isOnSite'] as bool?,
      );
}

class StationAccess {
  const StationAccess({this.description, required this.byMode, required this.interiorMaps});
  final String? description;
  final Map<String, List<AccessEntry>> byMode;
  final List<MapLink> interiorMaps;

  factory StationAccess.fromJson(Map<String, dynamic> j) {
    const known = {'bike', 'bus', 'parking', 'rail', 'airport'};
    final modes = <String, List<AccessEntry>>{};
    for (final e in j.entries) {
      if (e.value is List && known.contains(e.key)) {
        modes[e.key] = _list(e.value, AccessEntry.fromJson);
      }
    }
    return StationAccess(
      description: _str(j['description']),
      byMode: modes,
      interiorMaps: _list<MapLink?>(j['interiorMaps'], MapLink.tryParse).whereType<MapLink>().toList(growable: false),
    );
  }
}

class StationDetail {
  const StationDetail({required this.uid, this.facilities, this.access});
  final String uid;
  final StationFacilities? facilities;
  final StationAccess? access;

  factory StationDetail.fromJson(Map<String, dynamic> j) => StationDetail(
        uid: j['uid'] as String,
        facilities: j['facilities'] is Map
            ? StationFacilities.fromJson(Map<String, dynamic>.from(j['facilities'] as Map))
            : null,
        access: j['access'] is Map
            ? StationAccess.fromJson(Map<String, dynamic>.from(j['access'] as Map))
            : null,
      );
}
