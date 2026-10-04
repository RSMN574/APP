import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

class Speedometer extends StatefulWidget {
  const Speedometer({Key? key}) : super(key: key);

  @override
  State<Speedometer> createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<Speedometer> {
  // 數據監聽器
  final ValueNotifier<double> _currentSpeed = ValueNotifier(0.0);
  final ValueNotifier<double> _maxSpeed = ValueNotifier(0.0);
  final ValueNotifier<double> _averageSpeed = ValueNotifier(0.0);
  final ValueNotifier<double> _distance = ValueNotifier(0.0);
  final ValueNotifier<bool> _isOverSpeed = ValueNotifier(false);
  final ValueNotifier<double> _speedAnimation = ValueNotifier(0.0);
  final ValueNotifier<double> _altitude = ValueNotifier(0.0);
  final ValueNotifier<double> _accuracy = ValueNotifier(0.0);
  final ValueNotifier<int> _satellites = ValueNotifier(0);
  final ValueNotifier<DateTime> _tripStartTime = ValueNotifier(DateTime.now());
  final ValueNotifier<double> _topSpeedRecord = ValueNotifier(0.0);

  // 配置狀態
  final ValueNotifier<SpeedUnit> _selectedUnit = ValueNotifier(SpeedUnit.kmh);
  final ValueNotifier<int> _decimalPlaces = ValueNotifier(1);
  final ValueNotifier<double> _customSpeedLimit = ValueNotifier(50.0);
  final ValueNotifier<ColorTheme> _selectedTheme =
      ValueNotifier(ColorTheme.racingRed);
  final ValueNotifier<bool> _showDigitalSpeed = ValueNotifier(true);
  final ValueNotifier<bool> _showAnalogNeedle = ValueNotifier(true);
  final ValueNotifier<bool> _enableHUD = ValueNotifier(false);
  final ValueNotifier<double> _calibrationFactor = ValueNotifier(1.0);

  // 數據緩存
  final List<double> _speedBuffer = [];
  final List<SpeedRecord> _tripHistory = [];
  LatLng? _lastPosition;

  double _totalSpeed = 0;
  int _speedCount = 0;
  Timer? _tripTimer;
  Duration _tripDuration = Duration.zero;

  // GPS訂閱
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTripHistory();
    _startTracking();
    _startTripTimer();
  }

  // 加載設置
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedUnit.value = SpeedUnit.values[prefs.getInt('speedUnit') ?? 0];
    _decimalPlaces.value = prefs.getInt('decimalPlaces') ?? 1;
    _customSpeedLimit.value = prefs.getDouble('speedLimit') ?? 50.0;
    _selectedTheme.value = ColorTheme.values[prefs.getInt('colorTheme') ?? 0];
    _showDigitalSpeed.value = prefs.getBool('showDigitalSpeed') ?? true;
    _showAnalogNeedle.value = prefs.getBool('showAnalogNeedle') ?? true;
    _enableHUD.value = prefs.getBool('enableHUD') ?? false;
    _calibrationFactor.value = prefs.getDouble('calibrationFactor') ?? 1.0;
  }

  // 保存設置
  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('speedUnit', _selectedUnit.value.index);
    await prefs.setInt('decimalPlaces', _decimalPlaces.value);
    await prefs.setDouble('speedLimit', _customSpeedLimit.value);
    await prefs.setInt('colorTheme', _selectedTheme.value.index);
    await prefs.setBool('showDigitalSpeed', _showDigitalSpeed.value);
    await prefs.setBool('showAnalogNeedle', _showAnalogNeedle.value);
    await prefs.setBool('enableHUD', _enableHUD.value);
    await prefs.setDouble('calibrationFactor', _calibrationFactor.value);
  }

  // 加載歷史記錄
  void _loadTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('tripHistory') ?? [];
    _tripHistory.clear();
    for (var item in history) {
      final parts = item.split('|');
      if (parts.length == 3) {
        _tripHistory.add(SpeedRecord(
          speed: double.parse(parts[0]),
          timestamp: DateTime.parse(parts[1]),
          location: parts[2],
        ));
      }
    }
    if (_tripHistory.isNotEmpty) {
      _topSpeedRecord.value = _tripHistory.map((r) => r.speed).reduce(max);
    }
  }

  // 保存歷史記錄
  void _saveTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _tripHistory
        .take(10)
        .map((record) =>
            '${record.speed}|${record.timestamp.toIso8601String()}|${record.location}')
        .toList();
    await prefs.setStringList('tripHistory', history);
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(_updatePosition);
  }

  void _updatePosition(Position pos) {
    // 原始速度（m/s）
    double rawSpeed = pos.speed;

    // 校準
    double calibratedSpeed = rawSpeed * _calibrationFactor.value;

    // 單位轉換
    double speed = _convertToSelectedUnit(calibratedSpeed);

    // 精度平滑（卡爾曼濾波器）
    _speedBuffer.add(speed);
    if (_speedBuffer.length > 10) _speedBuffer.removeAt(0);

    // 加權平均，最新數據權重更高
    double smoothSpeed = 0;
    double totalWeight = 0;
    for (int i = 0; i < _speedBuffer.length; i++) {
      double weight = (i + 1) / _speedBuffer.length;
      smoothSpeed += _speedBuffer[i] * weight;
      totalWeight += weight;
    }
    smoothSpeed /= totalWeight;

    // 動畫過渡
    _speedAnimation.value = smoothSpeed;
    _currentSpeed.value = smoothSpeed;

    // 更新最高速度
    if (smoothSpeed > _maxSpeed.value) {
      _maxSpeed.value = smoothSpeed;

      // 記錄歷史最高速度
      if (smoothSpeed > _topSpeedRecord.value) {
        _topSpeedRecord.value = smoothSpeed;
        _recordSpeed(smoothSpeed, pos);
      }
    }

    // 更新平均速度
    _totalSpeed += smoothSpeed;
    _speedCount++;
    _averageSpeed.value = _totalSpeed / _speedCount;

    // 超速檢查
    _isOverSpeed.value = smoothSpeed > _customSpeedLimit.value;

    // 更新其他數據
    _altitude.value = pos.altitude;
    _accuracy.value = pos.accuracy;
    _satellites.value = pos.speedAccuracy > 0 ? 5 : 3; // 模擬衛星數量

    // 累計里程
    if (_lastPosition != null) {
      double d = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      _distance.value += _convertDistance(d);
    }
    _lastPosition = LatLng(pos.latitude, pos.longitude);
  }

  double _convertToSelectedUnit(double speedMs) {
    switch (_selectedUnit.value) {
      case SpeedUnit.kmh:
        return speedMs * 3.6;
      case SpeedUnit.mph:
        return speedMs * 2.23694;
      case SpeedUnit.ms:
        return speedMs;
      case SpeedUnit.knots:
        return speedMs * 1.94384;
    }
  }

  double _convertDistance(double meters) {
    switch (_selectedUnit.value) {
      case SpeedUnit.kmh:
        return meters / 1000;
      case SpeedUnit.mph:
        return meters / 1609.34;
      case SpeedUnit.ms:
        return meters;
      case SpeedUnit.knots:
        return meters / 1852;
    }
  }

  String _getDistanceUnit() {
    switch (_selectedUnit.value) {
      case SpeedUnit.kmh:
        return 'km';
      case SpeedUnit.mph:
        return 'mi';
      case SpeedUnit.ms:
        return 'm';
      case SpeedUnit.knots:
        return 'nm';
    }
  }

  void _recordSpeed(double speed, Position pos) {
    final record = SpeedRecord(
      speed: speed,
      timestamp: DateTime.now(),
      location:
          '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
    );
    _tripHistory.insert(0, record);
    if (_tripHistory.length > 100) _tripHistory.removeLast();
    _saveTripHistory();
  }

  void _startTripTimer() {
    _tripTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _tripDuration = _tripDuration + Duration(seconds: 1);
    });
  }

  void _resetTrip() {
    _maxSpeed.value = 0.0;
    _averageSpeed.value = 0.0;
    _distance.value = 0.0;
    _totalSpeed = 0;
    _speedCount = 0;
    _tripDuration = Duration.zero;
    _tripStartTime.value = DateTime.now();
    _speedBuffer.clear();
    _lastPosition = null;
  }

  void _calibrateSpeedometer(double referenceSpeed) {
    if (_currentSpeed.value > 0) {
      double factor = referenceSpeed / _currentSpeed.value;
      _calibrationFactor.value = factor;
      _saveSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('校準完成: ${factor.toStringAsFixed(3)}x'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _tripTimer?.cancel();
    _saveSettings();

    // 釋放所有ValueNotifier
    _currentSpeed.dispose();
    _maxSpeed.dispose();
    _averageSpeed.dispose();
    _distance.dispose();
    _isOverSpeed.dispose();
    _speedAnimation.dispose();
    _altitude.dispose();
    _accuracy.dispose();
    _satellites.dispose();
    _tripStartTime.dispose();
    _topSpeedRecord.dispose();
    _selectedUnit.dispose();
    _decimalPlaces.dispose();
    _customSpeedLimit.dispose();
    _selectedTheme.dispose();
    _showDigitalSpeed.dispose();
    _showAnalogNeedle.dispose();
    _enableHUD.dispose();
    _calibrationFactor.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text(
              'RACING DASHBOARD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.red,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: _showHistoryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景賽道效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black,
                    Color(0xFF1a0000),
                    Colors.black,
                  ],
                  stops: [0.1, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // 儀表板
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),

                  // 主儀表盤
                  ValueListenableBuilder5<double, bool, double, SpeedUnit,
                      ColorTheme>(
                    first: _currentSpeed,
                    second: _isOverSpeed,
                    third: _speedAnimation,
                    fourth: _selectedUnit,
                    fifth: _selectedTheme,
                    builder: (context, speed, overSpeed, animatedSpeed, unit,
                        theme, _) {
                      return Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getThemeColor(theme).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.9),
                              blurRadius: 30,
                              spreadRadius: -20,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(350, 350),
                              painter: _RacingSpeedometerPainter(
                                speed: animatedSpeed,
                                overSpeed: overSpeed,
                                maxSpeed: _maxSpeed.value,
                                unit: unit,
                                theme: theme,
                                showNeedle: _showAnalogNeedle.value,
                                decimalPlaces: _decimalPlaces.value,
                              ),
                            ),

                            // 數位速度顯示
                            ValueListenableBuilder<bool>(
                              valueListenable: _showDigitalSpeed,
                              builder: (context, showDigital, _) {
                                return AnimatedOpacity(
                                  opacity: showDigital ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 300),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${speed.toStringAsFixed(_decimalPlaces.value)}',
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Digital',
                                          color: overSpeed
                                              ? _getThemeColor(theme)
                                              : Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: overSpeed
                                                  ? _getThemeColor(theme)
                                                      .withOpacity(0.8)
                                                  : Colors.black,
                                              blurRadius: 30,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _getUnitString(unit),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // 中心紅點
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getThemeColor(theme),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _getThemeColor(theme).withOpacity(0.8),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30),

                  // 數據面板
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 第一行：速度記錄
                        Row(
                          children: [
                            Expanded(
                              child: _DataCard(
                                icon: Icons.rocket_launch,
                                title: AppLocalizations.of(context)!.text_472,
                                value: _maxSpeed,
                                unit: _selectedUnit,
                                decimalPlaces: _decimalPlaces,
                                theme: _selectedTheme,
                                isHighlighted: true,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _DataCard(
                                icon: Icons.trending_up,
                                title: AppLocalizations.of(context)!.text_473,
                                value: _averageSpeed,
                                unit: _selectedUnit,
                                decimalPlaces: _decimalPlaces,
                                theme: _selectedTheme,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // 第二行：行程數據
                        Row(
                          children: [
                            Expanded(
                              child: _DataCard(
                                icon: Icons.alt_route,
                                title: AppLocalizations.of(context)!.text_474,
                                value: _distance,
                                unit: _selectedUnit,
                                decimalPlaces: ValueNotifier(2),
                                isDistance: true,
                                theme: _selectedTheme,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ValueListenableBuilder<DateTime>(
                                valueListenable: _tripStartTime,
                                builder: (context, startTime, _) {
                                  final now = DateTime.now();
                                  final duration = now.difference(startTime);
                                  return _DataCard(
                                    icon: Icons.timer,
                                    title:
                                        AppLocalizations.of(context)!.text_475,
                                    value: ValueNotifier(
                                        duration.inMinutes / 60.0), // 小時
                                    unit: ValueNotifier(SpeedUnit.kmh), // 不使用
                                    decimalPlaces: ValueNotifier(1),
                                    customFormatter: (value) =>
                                        '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                                    theme: _selectedTheme,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // 第三行：GPS數據
                        Row(
                          children: [
                            Expanded(
                              child: _DataCard(
                                icon: Icons.height,
                                title: AppLocalizations.of(context)!.text_476,
                                value: _altitude,
                                unit: ValueNotifier(SpeedUnit.kmh),
                                decimalPlaces: ValueNotifier(0),
                                customFormatter: (double value) =>
                                    '${value.toStringAsFixed(0)} m', // 明確指定 double
                                theme: _selectedTheme,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _DataCard(
                                icon: Icons.gps_fixed,
                                title: AppLocalizations.of(context)!.text_477,
                                value: _accuracy,
                                unit: ValueNotifier(SpeedUnit.kmh),
                                decimalPlaces: ValueNotifier(1),
                                customFormatter: (double value) =>
                                    '±${value.toStringAsFixed(1)} m', // 明確指定 double
                                theme: _selectedTheme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // 控制按鈕
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 重置按鈕
                        _ControlButton(
                          icon: Icons.refresh,
                          label: AppLocalizations.of(context)!.text_478,
                          color: Colors.blue,
                          onPressed: () {
                            _showResetDialog();
                          },
                        ),

                        // 校準按鈕
                        _ControlButton(
                          icon: Icons.tune,
                          label: AppLocalizations.of(context)!.text_479,
                          color: Colors.amber,
                          onPressed: () {
                            _showCalibrationDialog();
                          },
                        ),

                        // 記錄按鈕
                        _ControlButton(
                          icon: Icons.flag,
                          label: AppLocalizations.of(context)!.text_480,
                          color: Colors.green,
                          onPressed: () {
                            if (_lastPosition != null) {
                              _recordSpeed(
                                  _currentSpeed.value,
                                  Position(
                                    latitude: _lastPosition!.latitude,
                                    longitude: _lastPosition!.longitude,
                                    timestamp: DateTime.now(),
                                    accuracy: 0,
                                    altitude: 0,
                                    heading: 0,
                                    speed: 0,
                                    speedAccuracy: 0,
                                    altitudeAccuracy: 0,
                                    headingAccuracy: 0,
                                  ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      AppLocalizations.of(context)!.text_481),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 超速警告（HUD模式）
          ValueListenableBuilder3<bool, bool, ColorTheme>(
            first: _isOverSpeed,
            second: _enableHUD,
            third: _selectedTheme,
            builder: (context, overSpeed, enableHUD, theme, _) {
              return AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                top: overSpeed && enableHUD ? 50 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _getThemeColor(theme).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 30),
                      SizedBox(width: 15),
                      Text(
                        'OVERSPEED WARNING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 15),
                      Icon(Icons.warning, color: Colors.white, size: 30),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(AppLocalizations.of(context)!.text_482,
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 單位選擇
                  _SettingsItem(
                    title: AppLocalizations.of(context)!.text_483,
                    child: DropdownButton<SpeedUnit>(
                      value: _selectedUnit.value,
                      dropdownColor: Colors.grey[900],
                      onChanged: (value) {
                        if (value != null) {
                          _selectedUnit.value = value;
                          _saveSettings();
                        }
                      },
                      items: SpeedUnit.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            _getUnitString(unit),
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 小數位數
                  _SettingsItem(
                    title: AppLocalizations.of(context)!.text_484,
                    child: DropdownButton<int>(
                      value: _decimalPlaces.value,
                      dropdownColor: Colors.grey[900],
                      onChanged: (value) {
                        if (value != null) {
                          _decimalPlaces.value = value;
                          _saveSettings();
                        }
                      },
                      items: [0, 1, 2, 3].map((places) {
                        return DropdownMenuItem(
                          value: places,
                          child: Text(
                            '$places 位',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 速度限制
                  _SettingsItem(
                    title: '速度限制 (${_getUnitString(_selectedUnit.value)})',
                    child: Slider(
                      value: _customSpeedLimit.value,
                      min: 10,
                      max: 200,
                      divisions: 38,
                      label: _customSpeedLimit.value.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          _customSpeedLimit.value = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _saveSettings();
                      },
                    ),
                  ),

                  // 主題選擇
                  _SettingsItem(
                    title: AppLocalizations.of(context)!.text_485,
                    child: DropdownButton<ColorTheme>(
                      value: _selectedTheme.value,
                      dropdownColor: Colors.grey[900],
                      onChanged: (value) {
                        if (value != null) {
                          _selectedTheme.value = value;
                          _saveSettings();
                        }
                      },
                      items: ColorTheme.values.map((theme) {
                        return DropdownMenuItem(
                          value: theme,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: _getThemeColor(theme),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                theme.toString().split('.').last,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 顯示選項
                  _SettingsItem(
                    title: AppLocalizations.of(context)!.text_486,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: _showDigitalSpeed.value,
                              onChanged: (value) {
                                _showDigitalSpeed.value = value;
                                _saveSettings();
                              },
                              activeColor: _getThemeColor(_selectedTheme.value),
                            ),
                            SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.text_487,
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        Row(
                          children: [
                            Switch(
                              value: _showAnalogNeedle.value,
                              onChanged: (value) {
                                _showAnalogNeedle.value = value;
                                _saveSettings();
                              },
                              activeColor: _getThemeColor(_selectedTheme.value),
                            ),
                            SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.text_488,
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        Row(
                          children: [
                            Switch(
                              value: _enableHUD.value,
                              onChanged: (value) {
                                _enableHUD.value = value;
                                _saveSettings();
                              },
                              activeColor: _getThemeColor(_selectedTheme.value),
                            ),
                            SizedBox(width: 10),
                            Text('HUD警告',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 校準因子
                  _SettingsItem(
                    title:
                        '校準因子: ${_calibrationFactor.value.toStringAsFixed(3)}',
                    child: Slider(
                      value: _calibrationFactor.value,
                      min: 0.8,
                      max: 1.2,
                      divisions: 40,
                      label: _calibrationFactor.value.toStringAsFixed(3),
                      onChanged: (value) {
                        setState(() {
                          _calibrationFactor.value = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.text_44,
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.white),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.text_489,
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _tripHistory.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.text_490,
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _tripHistory.length,
                  itemBuilder: (context, index) {
                    final record = _tripHistory[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getThemeColor(_selectedTheme.value),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${record.speed.toStringAsFixed(_decimalPlaces.value)} ${_getUnitString(_selectedUnit.value)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  record.timestamp.toString().substring(0, 16),
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  record.location,
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tripHistory.clear();
              _topSpeedRecord.value = 0;
              _saveTripHistory();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.text_491,
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.text_44,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(AppLocalizations.of(context)!.text_492,
            style: TextStyle(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context)!.text_493,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.text_36,
                style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              _resetTrip();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.text_494),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.text_478,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    double referenceSpeed = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(AppLocalizations.of(context)!.text_495,
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.text_496,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 20),
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '參考速度 (${_getUnitString(_selectedUnit.value)})',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: _getThemeColor(_selectedTheme.value)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    referenceSpeed = double.tryParse(value) ?? 0;
                  },
                ),
                SizedBox(height: 10),
                Text(
                  '當前速度: ${_currentSpeed.value.toStringAsFixed(_decimalPlaces.value)} ${_getUnitString(_selectedUnit.value)}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.text_36,
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  if (referenceSpeed > 0) {
                    _calibrateSpeedometer(referenceSpeed);
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.text_479,
                    style:
                        TextStyle(color: _getThemeColor(_selectedTheme.value))),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getThemeColor(ColorTheme theme) {
    switch (theme) {
      case ColorTheme.racingRed:
        return Color(0xFFff0000);
      case ColorTheme.blueNeon:
        return Color(0xFF00a8ff);
      case ColorTheme.greenCyber:
        return Color(0xFF00ff9d);
      case ColorTheme.purpleLaser:
        return Color(0xFF9d00ff);
      case ColorTheme.orangeFlame:
        return Color(0xFFff6b00);
    }
  }

  String _getUnitString(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.kmh:
        return 'km/h';
      case SpeedUnit.mph:
        return 'mph';
      case SpeedUnit.ms:
        return 'm/s';
      case SpeedUnit.knots:
        return 'knots';
    }
  }
}

// -------------------- 數據卡片 --------------------
class _DataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final ValueNotifier<double> value;
  final ValueNotifier<SpeedUnit> unit;
  final ValueNotifier<int> decimalPlaces;
  final ValueNotifier<ColorTheme> theme;
  final bool isHighlighted;
  final bool isDistance;
  final String Function(double)? customFormatter; // 這裡修正為 double

  const _DataCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.decimalPlaces,
    required this.theme,
    this.isHighlighted = false,
    this.isDistance = false,
    this.customFormatter, // 修正類型
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder5<double, int, SpeedUnit, ColorTheme, bool>(
      first: value,
      second: decimalPlaces,
      third: unit,
      fourth: theme,
      fifth: ValueNotifier(isDistance),
      builder: (context, val, places, unit, theme, isDist, _) {
        final color = isHighlighted ? _getThemeColor(theme) : Colors.white;
        String displayValue;

        if (customFormatter != null) {
          displayValue = customFormatter!(val);
        } else if (isDist) {
          displayValue =
              '${val.toStringAsFixed(places)} ${_getDistanceUnit(unit)}';
        } else {
          displayValue = '${val.toStringAsFixed(places)}';
        }

        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? color.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                displayValue,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Digital',
                  height: 1.0,
                ),
              ),
              if (!isDist && customFormatter == null)
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    _getUnitString(unit),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getThemeColor(ColorTheme theme) {
    switch (theme) {
      case ColorTheme.racingRed:
        return Color(0xFFff0000);
      case ColorTheme.blueNeon:
        return Color(0xFF00a8ff);
      case ColorTheme.greenCyber:
        return Color(0xFF00ff9d);
      case ColorTheme.purpleLaser:
        return Color(0xFF9d00ff);
      case ColorTheme.orangeFlame:
        return Color(0xFFff6b00);
    }
  }

  String _getUnitString(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.kmh:
        return 'km/h';
      case SpeedUnit.mph:
        return 'mph';
      case SpeedUnit.ms:
        return 'm/s';
      case SpeedUnit.knots:
        return 'knots';
    }
  }

  String _getDistanceUnit(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.kmh:
        return 'km';
      case SpeedUnit.mph:
        return 'mi';
      case SpeedUnit.ms:
        return 'm';
      case SpeedUnit.knots:
        return 'nm';
    }
  }
}

// -------------------- 控制按鈕 --------------------
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 設置項目 --------------------
class _SettingsItem extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsItem({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// -------------------- 跑車風格儀表盤畫筆 --------------------
class _RacingSpeedometerPainter extends CustomPainter {
  final double speed;
  final bool overSpeed;
  final double maxSpeed;
  final SpeedUnit unit;
  final ColorTheme theme;
  final bool showNeedle;
  final int decimalPlaces;

  _RacingSpeedometerPainter({
    required this.speed,
    required this.overSpeed,
    required this.maxSpeed,
    required this.unit,
    required this.theme,
    required this.showNeedle,
    required this.decimalPlaces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final color = _getThemeColor(theme);

    // 1. 背景光暈
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(overSpeed ? 0.3 : 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius, outerGlowPaint);

    // 2. 金屬環
    final metalRingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF333333),
          Color(0xFF1a1a1a),
          Color(0xFF333333),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 6, metalRingPaint);

    // 3. 內環
    final innerRingPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Color(0xFF0a0a0a),
          Color(0xFF000000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 20))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 20, innerRingPaint);

    // 4. 速度刻度 (240度範圍)
    final double startAngle = -pi * 5 / 6; // 225度
    final double sweepAngle = pi * 4 / 3; // 240度
    final double maxDisplaySpeed = _getMaxSpeedForUnit(unit);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius - 40);

    // 刻度背景
    final scaleBgPaint = Paint()
      ..color = Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, scaleBgPaint);

    // 5. 速度進度條 (漸層)
    final progress = (speed / maxDisplaySpeed).clamp(0.0, 1.0);
    final gradientArcPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color,
          color.withOpacity(0.7),
          color.withOpacity(0.3),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        arcRect, startAngle, sweepAngle * progress, false, gradientArcPaint);

    // 6. 刻度線和數字
    final scalePaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final majorScalePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    int majorInterval = _getMajorInterval(maxDisplaySpeed);
    int totalDivisions = (maxDisplaySpeed ~/ (majorInterval / 3)).toInt();

    for (int i = 0; i <= totalDivisions; i++) {
      double value = i * (maxDisplaySpeed / totalDivisions);
      double angle = startAngle + (sweepAngle * value / maxDisplaySpeed);

      bool isMajor = (i % 3 == 0);
      double scaleLength = isMajor ? 20 : 12;

      Offset start = Offset(
        center.dx + (radius - 60) * cos(angle),
        center.dy + (radius - 60) * sin(angle),
      );
      Offset end = Offset(
        center.dx + (radius - 60 - scaleLength) * cos(angle),
        center.dy + (radius - 60 - scaleLength) * sin(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorScalePaint : scalePaint);

      // 繪製主要刻度數字
      if (isMajor && value <= maxDisplaySpeed) {
        textPainter.text = TextSpan(
          text: '${value.toInt()}',
          style: TextStyle(
            color: value <= speed ? color : Colors.white60,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        double textRadius = radius - 90;
        Offset textPos = Offset(
          center.dx + textRadius * cos(angle) - textPainter.width / 2,
          center.dy + textRadius * sin(angle) - textPainter.height / 2,
        );

        textPainter.paint(canvas, textPos);
      }
    }

    // 7. 最高速度標記
    if (maxSpeed > 0) {
      double maxSpeedAngle =
          startAngle + (sweepAngle * maxSpeed / maxDisplaySpeed);
      final maxSpeedPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        arcRect,
        maxSpeedAngle - 0.02,
        0.04,
        false,
        maxSpeedPaint,
      );
    }

    // 8. 指針
    if (showNeedle) {
      final double needleAngle = startAngle + (sweepAngle * progress);

      // 指針陰影
      final needleShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      // 指針本體
      final needlePaint = Paint()
        ..shader = LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ).createShader(
            Rect.fromPoints(center, Offset(center.dx + 100, center.dy)))
        ..style = PaintingStyle.fill;

      // 精密指針設計
      Path needlePath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius - 60, center.dy - 3)
        ..lineTo(center.dx + radius - 40, center.dy)
        ..lineTo(center.dx + radius - 60, center.dy + 3)
        ..close();

      // 指針尾翼
      Path needleTail = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx - 20, center.dy - 8)
        ..lineTo(center.dx - 20, center.dy + 8)
        ..close();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(needleAngle);
      canvas.translate(-center.dx, -center.dy);

      // 畫陰影
      canvas.drawPath(needlePath.shift(Offset(3, 3)), needleShadowPaint);
      canvas.drawPath(needleTail.shift(Offset(3, 3)), needleShadowPaint);

      // 畫指針
      canvas.drawPath(needlePath, needlePaint);
      canvas.drawPath(needleTail, needlePaint);

      canvas.restore();
    }

    // 9. 碳纖維紋理
    final carbonPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        if ((i + j) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              center.dx - radius + (i * 24),
              center.dy - radius + (j * 24),
              12,
              12,
            ),
            carbonPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RacingSpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.overSpeed != overSpeed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.unit != unit ||
        oldDelegate.theme != theme ||
        oldDelegate.showNeedle != showNeedle ||
        oldDelegate.decimalPlaces != decimalPlaces;
  }

  Color _getThemeColor(ColorTheme theme) {
    switch (theme) {
      case ColorTheme.racingRed:
        return Color(0xFFff0000);
      case ColorTheme.blueNeon:
        return Color(0xFF00a8ff);
      case ColorTheme.greenCyber:
        return Color(0xFF00ff9d);
      case ColorTheme.purpleLaser:
        return Color(0xFF9d00ff);
      case ColorTheme.orangeFlame:
        return Color(0xFFff6b00);
    }
  }

  double _getMaxSpeedForUnit(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.kmh:
        return 240;
      case SpeedUnit.mph:
        return 150;
      case SpeedUnit.ms:
        return 67;
      case SpeedUnit.knots:
        return 130;
    }
  }

  int _getMajorInterval(double maxSpeed) {
    if (maxSpeed <= 100) return 20;
    if (maxSpeed <= 200) return 40;
    return 60;
  }
}

// -------------------- 輔助類和枚舉 --------------------

enum SpeedUnit {
  kmh,
  mph,
  ms,
  knots,
}

enum ColorTheme {
  racingRed,
  blueNeon,
  greenCyber,
  purpleLaser,
  orangeFlame,
}

class SpeedRecord {
  final double speed;
  final DateTime timestamp;
  final String location;

  SpeedRecord({
    required this.speed,
    required this.timestamp,
    required this.location,
  });
}

// -------------------- 多個ValueListenableBuilder組合 --------------------

class ValueListenableBuilder5<A, B, C, D, E> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final ValueNotifier<D> fourth;
  final ValueNotifier<E> fifth;
  final Widget Function(BuildContext, A, B, C, D, E, Widget?) builder;

  const ValueListenableBuilder5({
    Key? key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.fifth,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valB, __) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, valC, ___) {
                return ValueListenableBuilder<D>(
                  valueListenable: fourth,
                  builder: (context, valD, ____) {
                    return ValueListenableBuilder<E>(
                      valueListenable: fifth,
                      builder: (context, valE, _____) {
                        return builder(
                            context, valA, valB, valC, valD, valE, null);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// 2個、3個、4個ValueListenableBuilder的版本（已存在，這裡省略）
// -------------------- ValueListenableBuilder3 --------------------
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;

  const ValueListenableBuilder3({
    Key? key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valB, __) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, valC, ___) {
                return builder(context, valA, valB, valC, null);
              },
            );
          },
        );
      },
    );
  }
}

// -------------------- ValueListenableBuilder2（如果需要）--------------------
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    Key? key,
    required this.first,
    required this.second,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valB, __) {
            return builder(context, valA, valB, null);
          },
        );
      },
    );
  }
}

// -------------------- ValueListenableBuilder4（如果需要）--------------------
class ValueListenableBuilder4<A, B, C, D> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final ValueNotifier<D> fourth;
  final Widget Function(BuildContext, A, B, C, D, Widget?) builder;

  const ValueListenableBuilder4({
    Key? key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valB, __) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, valC, ___) {
                return ValueListenableBuilder<D>(
                  valueListenable: fourth,
                  builder: (context, valD, ____) {
                    return builder(context, valA, valB, valC, valD, null);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
