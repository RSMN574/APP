import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/getData.dart';

class MileagePage extends StatefulWidget {
  const MileagePage({super.key});

  @override
  State<MileagePage> createState() => _MileagePageState();
}

class _MileagePageState extends State<MileagePage> {
  static const String _storageKey = 'rail_mileage_records';
  static const Color _traColor = Color(0xFF2A5CAA);
  static const Color _hsrColor = Color(0xFFDC5321);
  static const Color _surfaceColor = Color(0xFFF3F5F7);
  static const Color _textPrimary = Color(0xFF2D3748);
  static const Color _textSecondary = Color(0xFF718096);

  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _trainNoController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _rawController = TextEditingController();

  List<MileageRecord> _records = [];
  RailOperator _selectedOperator = RailOperator.tra;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _timeController.text = _dateFormat.format(DateTime.now());
    _loadRecords();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _trainNoController.dispose();
    _timeController.dispose();
    _rawController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      _records = payload
          .map((item) => MileageRecord.fromJson(json.decode(item)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _records.map((record) => json.encode(record.toJson())).toList(),
    );
  }

  Future<void> _openScanner() async {
    final rawValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RailQrScannerPage()),
    );
    if (rawValue == null || rawValue.trim().isEmpty) return;
    _rawController.text = rawValue.trim();
    final parsed = RailQrParser.parse(rawValue);
    _originController.text = parsed.origin ?? '';
    _destinationController.text = parsed.destination ?? '';
    _trainNoController.text = parsed.trainNo ?? '';
    setState(() {
      _selectedOperator = parsed.operator ?? _selectedOperator;
    });
    if (parsed.origin != null && parsed.destination != null) {
      await _addRecord();
    } else {
      _showMessage('已讀取 QR，請補上起訖站後儲存');
    }
  }

  Future<void> _addRecord() async {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    final trainNo = _trainNoController.text.trim();
    final timeStr = _timeController.text.trim();

    if (origin.isEmpty || destination.isEmpty) {
      _showMessage('請輸入起站與迄站');
      return;
    }
    if (origin == destination) {
      _showMessage('起站與迄站不能相同');
      return;
    }
    if (trainNo.isEmpty) {
      _showMessage('請輸入車次');
      return;
    }
    if (timeStr.isEmpty) {
      _showMessage('請輸入時間');
      return;
    }

    DateTime? travelTime;
    try {
      travelTime = _dateFormat.parse(timeStr);
    } catch (e) {
      _showMessage('時間格式錯誤 (yyyy/MM/dd HH:mm)');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final distance = await _calculateMileage(
        origin,
        destination,
        _selectedOperator,
      );
      final record = MileageRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        operator: _selectedOperator,
        origin: origin,
        destination: destination,
        trainNo: trainNo,
        distanceKm: distance,
        rawQr: _rawController.text.trim(),
        createdAt: travelTime,
      );
      setState(() {
        _records = [record, ..._records];
        _originController.clear();
        _destinationController.clear();
        _trainNoController.clear();
        _timeController.text = _dateFormat.format(DateTime.now());
        _rawController.clear();
      });
      await _saveRecords();
      _showMessage('已新增 ${distance.toStringAsFixed(1)} km');
    } catch (error) {
      _showMessage('找不到站點或里程計算失敗');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<double> _calculateMileage(
      String origin,
      String destination,
      RailOperator operator,
      ) async {
    final stationTable = operator == RailOperator.hsr
        ? 'HSR.HSR_Station'
        : 'Train.Train_Station';
    final originStation = await _findStation(stationTable, origin);
    final destinationStation = await _findStation(stationTable, destination);

    if (originStation == null || destinationStation == null) {
      throw StateError('Station not found');
    }

    // 優先使用營業里程計算
    if (operator == RailOperator.hsr) {
      final hsrMileage = {
        '南港': 0.0, '台北': 9.2, '板橋': 16.3, '桃園': 42.3, '新竹': 72.2,
        '苗栗': 102.8, '台中': 165.7, '彰化': 193.9, '雲林': 218.5,
        '嘉義': 251.6, '台南': 311.1, '左營': 339.3
      };

      String? oName, dName;
      hsrMileage.forEach((name, _) {
        if (originStation['StationName'].toString().contains(name)) oName = name;
        if (destinationStation['StationName'].toString().contains(name)) dName = name;
      });

      if (oName != null && dName != null) {
        return (hsrMileage[dName]! - hsrMileage[oName]!).abs();
      }
    } else {
      // 台鐵營業里程計算
      final oId = originStation['StationID'];
      final dId = destinationStation['StationID'];

      // 這裡假設我們有一個台鐵里程表，若找不到則回退到直線距離
      final traMil = await _getTraBusinessMileage(oId, dId);
      if (traMil != null) return traMil;
    }

    // 回退方案：使用球面距離計算（直線距離）
    final originPosition = _readPosition(originStation['StationPosition']);
    final destinationPosition =
    _readPosition(destinationStation['StationPosition']);
    return _distanceInKm(
      originPosition.latitude,
      originPosition.longitude,
      destinationPosition.latitude,
      destinationPosition.longitude,
    );
  }

  Future<double?> _getTraBusinessMileage(String originId, String destinationId) async {
    try {
      // 從資料庫獲取營業里程數據 (staMil)
      final rows = await mysqlSelect(
          "SELECT fkSta, staMil FROM Train.Train_Mileage WHERE fkSta IN ('$originId', '$destinationId')"
      );
      if (rows != null && rows.length >= 2) {
        double? oMil, dMil;
        for (var row in rows) {
          if (row['fkSta'] == originId) oMil = double.tryParse(row['staMil'].toString());
          if (row['fkSta'] == destinationId) dMil = double.tryParse(row['staMil'].toString());
        }
        if (oMil != null && dMil != null) return (dMil - oMil).abs();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _findStation(String table, String keyword) async {
    final escaped = keyword.replaceAll("'", "''");
    final rows = await mysqlSelect(
      "SELECT StationID, StationName, StationPosition FROM $table "
          "WHERE StationID = '$escaped' "
          "OR JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%$escaped%' "
          "OR JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.En')) LIKE '%$escaped%' "
          "LIMIT 1;",
    );
    if (rows == null || rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  _StationPosition _readPosition(dynamic value) {
    final data = value is String ? json.decode(value) : value;
    return _StationPosition(
      (data['PositionLat'] as num).toDouble(),
      (data['PositionLon'] as num).toDouble(),
    );
  }

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreeToRadian(lat2 - lat1);
    final dLon = _degreeToRadian(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degreeToRadian(double degree) => degree * pi / 180;

  Future<void> _deleteRecord(MileageRecord record) async {
    setState(() {
      _records = _records.where((item) => item.id != record.id).toList();
    });
    await _saveRecords();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  double get _totalMileage =>
      _records.fold(0, (sum, record) => sum + record.distanceKm);

  double _operatorMileage(RailOperator operator) => _records
      .where((record) => record.operator == operator)
      .fold(0, (sum, record) => sum + record.distanceKm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text('鐵道里程'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummary(),
            const SizedBox(height: 16),
            _buildInputPanel(),
            const SizedBox(height: 16),
            _buildRecordList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '累積里程',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalMileage.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  '台鐵',
                  _operatorMileage(RailOperator.tra),
                  _traColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  '高鐵',
                  _operatorMileage(RailOperator.hsr),
                  _hsrColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)} km',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SegmentedButton<RailOperator>(
            segments: const [
              ButtonSegment(
                value: RailOperator.tra,
                label: Text('台鐵'),
                icon: Icon(Icons.train_rounded),
              ),
              ButtonSegment(
                value: RailOperator.hsr,
                label: Text('高鐵'),
                icon: Icon(Icons.train_outlined),
              ),
            ],
            selected: {_selectedOperator},
            onSelectionChanged: (value) {
              setState(() => _selectedOperator = value.first);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(_originController, '起站')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_destinationController, '迄站')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(_trainNoController, '車次')),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date == null) return;
                    if (!mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setState(() {
                      _timeController.text = _dateFormat.format(DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ));
                    });
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(_timeController, '時間'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('掃描 QR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _addRecord,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.add_rounded),
                  label: const Text('新增紀錄'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    if (_records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('還沒有里程紀錄'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '搭乘紀錄',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ..._records.map((record) => _buildRecordTile(record)),
      ],
    );
  }

  Widget _buildRecordTile(MileageRecord record) {
    final color = record.operator == RailOperator.hsr ? _hsrColor : _traColor;
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteRecord(record),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            foregroundColor: color,
            child: Icon(record.operator == RailOperator.hsr
                ? Icons.train_outlined
                : Icons.train_rounded),
          ),
          title: Text('${record.origin} → ${record.destination}'),
          subtitle: Text(
            '${record.operator.label}${record.trainNo.isEmpty ? '' : ' · ${record.trainNo}'} · ${_dateFormat.format(record.createdAt)}',
          ),
          trailing: Text(
            '${record.distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class RailQrScannerPage extends StatefulWidget {
  const RailQrScannerPage({super.key});

  @override
  State<RailQrScannerPage> createState() => _RailQrScannerPageState();
}

class _RailQrScannerPageState extends State<RailQrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('掃描車票 QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          String? value;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              value = barcode.rawValue;
              break;
            }
          }
          if (value == null || value.isEmpty) return;
          _handled = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}

class RailQrParser {
  static ParsedRailQr parse(String rawValue) {
    final value = rawValue.trim();
    final operator = _detectOperator(value);
    final uri = Uri.tryParse(value);
    final params = <String, String>{};
    if (uri != null) {
      params.addAll(uri.queryParameters);
    }

    Map<String, dynamic>? jsonMap;
    try {
      final decoded = json.decode(value);
      if (decoded is Map<String, dynamic>) jsonMap = decoded;
    } catch (_) {}

    String? read(List<String> keys) {
      for (final key in keys) {
        final param = params[key];
        if (param != null && param.trim().isNotEmpty) return param.trim();
        final jsonValue = jsonMap?[key];
        if (jsonValue != null && jsonValue.toString().trim().isNotEmpty) {
          return jsonValue.toString().trim();
        }
      }
      return null;
    }

    final origin = read([
      'origin',
      'from',
      'start',
      'departure',
      'originStation',
      '起站',
      '出發站',
    ]);
    final destination = read([
      'destination',
      'to',
      'end',
      'arrival',
      'destinationStation',
      '迄站',
      '到達站',
    ]);
    final trainNo = read(['trainNo', 'train', '車次', 'ticketNo', '票號']);

    return ParsedRailQr(
      operator: operator,
      origin: origin,
      destination: destination,
      trainNo: trainNo,
    );
  }

  static RailOperator? _detectOperator(String value) {
    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('thsr') || value.contains('高鐵')) {
      return RailOperator.hsr;
    }
    if (lowerValue.contains('tra') ||
        value.contains('台鐵') ||
        value.contains('臺鐵')) {
      return RailOperator.tra;
    }
    return null;
  }
}

class ParsedRailQr {
  final RailOperator? operator;
  final String? origin;
  final String? destination;
  final String? trainNo;

  ParsedRailQr({
    required this.operator,
    required this.origin,
    required this.destination,
    required this.trainNo,
  });
}

class MileageRecord {
  final String id;
  final RailOperator operator;
  final String origin;
  final String destination;
  final String trainNo;
  final double distanceKm;
  final String rawQr;
  final DateTime createdAt;

  MileageRecord({
    required this.id,
    required this.operator,
    required this.origin,
    required this.destination,
    required this.trainNo,
    required this.distanceKm,
    required this.rawQr,
    required this.createdAt,
  });

  factory MileageRecord.fromJson(Map<String, dynamic> json) {
    return MileageRecord(
      id: json['id'],
      operator: RailOperator.values.firstWhere(
            (item) => item.name == json['operator'],
        orElse: () => RailOperator.tra,
      ),
      origin: json['origin'],
      destination: json['destination'],
      trainNo: json['trainNo'] ?? '',
      distanceKm: (json['distanceKm'] as num).toDouble(),
      rawQr: json['rawQr'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator': operator.name,
      'origin': origin,
      'destination': destination,
      'trainNo': trainNo,
      'distanceKm': distanceKm,
      'rawQr': rawQr,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class _StationPosition {
  final double latitude;
  final double longitude;

  _StationPosition(this.latitude, this.longitude);
}

enum RailOperator {
  tra('台鐵'),
  hsr('高鐵');

  final String label;
  const RailOperator(this.label);
}
