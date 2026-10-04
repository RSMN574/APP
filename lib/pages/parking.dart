import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const/regular_class.dart';
import '../const/regular_const.dart';
import '../database/ev_station/ev_station.dart';
import '../database/park/get_park.dart';
import '../utils/convert.dart';
import '../utils/share.dart';
import '../l10n/app_localizations.dart';
import '../widget/map.dart';

/// 🟢 強型別停車場資料模型
/// 目的：將原本散落各處且反覆 json.decode 的資料在網絡層一次性解析完畢
/// 效能：解決原本 ListView 滑動與 Marker 產生時大量 CPU 解碼導致的卡頓
class ParkingLot {
  final String id;
  final String name;
  final String nameEn;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final int? totalSpaces;
  final int? availableSpaces;
  final String fareDescription;
  final dynamic carParkType;
  final dynamic chargeTypes;
  final String description;
  final bool isFreeOutOfHours;
  final bool hasEV;
  final bool overnightPermitted;
  final bool vehicleDetection;
  final bool wheelchairAccessible;

  ParkingLot({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    this.totalSpaces,
    this.availableSpaces,
    required this.fareDescription,
    this.carParkType,
    this.chargeTypes,
    required this.description,
    required this.isFreeOutOfHours,
    required this.hasEV,
    required this.overnightPermitted,
    required this.vehicleDetection,
    required this.wheelchairAccessible,
  });

  /// 工廠建構子：安全解析靜態 (MySQL) + 即時 (TDX) 資料
  factory ParkingLot.fromMap(
      Map<String, dynamic> park,
      Map<String, dynamic>? live,
      ) {
    // 1. 安全解析停車場名稱
    String parkName = "未命名停車場";
    String parkNameEn = "";
    try {
      if (park["CarParkName"] != null) {
        final decodedName = park["CarParkName"] is String
            ? json.decode(park["CarParkName"])
            : park["CarParkName"];
        if (decodedName is Map) {
          if (decodedName["Zh_tw"] != null) {
            parkName = decodedName["Zh_tw"].toString();
          }
          if (decodedName["En"] != null) {
            parkNameEn = decodedName["En"].toString();
          }
        }
      }
    } catch (_) {}

    // 2. 安全解析經緯度 (修復原版導航時經緯度永遠為 0.0 的致命 Bug)
    double lat = 0.0;
    double lng = 0.0;
    try {
      if (park["CarParkPosition"] != null) {
        final pos = park["CarParkPosition"] is String
            ? json.decode(park["CarParkPosition"])
            : park["CarParkPosition"];
        if (pos is Map) {
          lat = double.tryParse(pos["PositionLat"].toString()) ?? 0.0;
          lng = double.tryParse(pos["PositionLon"].toString()) ?? 0.0;
        }
      }
    } catch (_) {}

    // 3. 安全解析即時車位資訊
    int? parseSpace(dynamic val) {
      if (val == null) return null;
      return int.tryParse(val.toString());
    }

    return ParkingLot(
      id: park["CarParkID"]?.toString() ?? "",
      name: parkName,
      nameEn: parkNameEn,
      address: park["Address"]?.toString() ?? "無地址資訊",
      phone: park["Telephone"]?.toString() ?? "",
      lat: lat,
      lng: lng,
      totalSpaces: parseSpace(live?["TotalSpaces"] ?? park["TotalSpaces"]),
      availableSpaces: parseSpace(
        live?["AvailableSpaces"] ?? park["AvailableSpaces"],
      ),
      fareDescription: park["FareDescription"]?.toString() ?? "",
      carParkType: park["CarParkType"],
      chargeTypes: park["ChargeTypes"],
      description: park["Description"]?.toString() ?? "無營運描述",
      isFreeOutOfHours: park["IsFreeParkingOutOfHours"] == "1" ||
          park["IsFreeParkingOutOfHours"] == 1,
      hasEV: park["EVRechargingAvailable"] == "1" ||
          park["EVRechargingAvailable"] == 1,
      overnightPermitted:
      park["OvernightPermitted"] == "1" || park["OvernightPermitted"] == 1,
      vehicleDetection:
      park["VehicleDetection"] == "1" || park["VehicleDetection"] == 1,
      wheelchairAccessible: park["WheelchairAccessible"] == "1" ||
          park["WheelchairAccessible"] == 1,
    );
  }

  String localizedName(String languageCode) {
    if (languageCode != 'en') return name;
    if (nameEn.trim().isNotEmpty) return nameEn;
    return name == '未命名停車場' ? 'Unnamed Parking Lot' : name;
  }

  /// 轉回 Map 物件以供 StationActions.shareStation 等接收 Map 的函式使用
  Map<String, dynamic> toMap() {
    return {
      "CarParkID": id,
      "CarParkName": {
        "Zh_tw": name,
        if (nameEn.isNotEmpty) "En": nameEn,
      },
      "Address": address,
      "Telephone": phone,
      "FareDescription": fareDescription,
      "TotalSpaces": totalSpaces,
      "AvailableSpaces": availableSpaces,
      "CarParkPosition": {
        "PositionLat": lat,
        "PositionLon": lng,
      },
    };
  }

  /// 計算車位緊張度等級
  String get capacityLevel {
    if (totalSpaces == null || availableSpaces == null || totalSpaces == 0) {
      return "⚪";
    }
    final ratio = (availableSpaces! / totalSpaces!).clamp(0.0, 1.0);
    if (ratio >= 0.5) return "🟢";
    if (ratio >= 0.2) return "🟡";
    return "🔴";
  }

  /// 計算狀態顏色
  Color get capacityColor {
    if (totalSpaces == null || availableSpaces == null || totalSpaces == 0) {
      return const Color(0xFF8E8E93);
    }
    final ratio = (availableSpaces! / totalSpaces!).clamp(0.0, 1.0);
    if (ratio >= 0.5) return const Color(0xFF34C759);
    if (ratio >= 0.2) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  /// 取得容量文字描述
  String capacityTextFor(String languageCode) {
    if (totalSpaces == null || availableSpaces == null || totalSpaces == 0) {
      return languageCode == 'en' ? 'No data' : "無資料";
    }
    final ratio = (availableSpaces! / totalSpaces!).clamp(0.0, 1.0);
    if (ratio >= 0.5) return languageCode == 'en' ? 'Plenty' : "充足";
    if (ratio >= 0.2) return languageCode == 'en' ? 'Moderate' : "普通";
    return languageCode == 'en' ? 'Limited' : "緊張";
  }

  String get capacityText => capacityTextFor('zh');
}

final List<CityItem> cities = [
  CityItem(name: '臺中市', id: 'Taichung'),
  CityItem(name: '桃園市', id: 'Taoyuan'),
];

class Parking extends StatefulWidget {
  const Parking({super.key});

  @override
  State<Parking> createState() => _ParkingState();
}

class _ParkingState extends State<Parking> {
  // 城市切換控制
  late final ValueNotifier<String> _currentCityNotifier;
  late final ValueNotifier<String> _correspondingIDNotifier;
  String _selectedCity = "臺中市";

  // 地圖與搜尋控制
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // 搜尋防抖器 (Debouncer) 防止高頻過濾造成 App 畫面格頓
  Timer? _searchDebounceTimer;

  // 資料列表 (使用模型物件)
  List<ParkingLot> _allParking = [];
  List<ParkingLot> _filteredStations = [];

  bool _isLoading = true;
  bool _hasLoadError = false;

  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';

  String _cityName(CityItem city) {
    if (!_isEnglish) return city.name;
    return switch (city.id) {
      'Taichung' => 'Taichung',
      'Taoyuan' => 'Taoyuan',
      'all' => 'All',
      _ => city.name,
    };
  }

  String _localizedParkingValue(String value) {
    if (!_isEnglish) return value;
    final l10n = AppLocalizations.of(context)!;
    return switch (value) {
      '未命名停車場' => l10n.text_500,
      '無地址資訊' => l10n.text_501,
      '無資料' || '無營運描述' || '無費率資訊' => l10n.text_508,
      _ => value,
    };
  }

  @override
  void initState() {
    super.initState();
    _currentCityNotifier = ValueNotifier<String>("臺中市");
    _correspondingIDNotifier = ValueNotifier<String>("Taichung");

    // 設定搜尋輸入監聽
    _searchController.addListener(_onSearchInputChanged);
    _fetchData();
  }

  @override
  void dispose() {
    // 🚀 安全釋放控制器，防止記憶體洩漏 (Memory Leak)
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _currentCityNotifier.dispose();
    _correspondingIDNotifier.dispose();

    // 離開頁面時清空地圖 Marker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
      }
    });
    super.dispose();
  }

  /// 獲取與整合靜態/動態停車場資料
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    try {
      final cityCode = _correspondingIDNotifier.value;

      /// 1. 併發讀取 MySQL 靜態資料庫 (提升載入效率)
      final results = await Future.wait([
        mysqlSelect('SELECT * FROM CarPark.OffStreetCarPark_$cityCode;'),
        mysqlSelect(
          'SELECT * FROM CarPark.OffStreetCarPark_Freeway WHERE CityCode="${convertCityCode(cityCode)}";',
        ),
        mysqlSelect(
          'SELECT * FROM CarPark.OffStreetCarPark_TRA WHERE CityCode="${convertCityCode(cityCode)}";',
        ),
        mysqlSelect(
          'SELECT * FROM CarPark.OffStreetCarPark_THSR WHERE CityCode="${convertCityCode(cityCode)}";',
        ),
      ]);

      final rawOffStreet = results[0] ?? [];
      final rawFreeway = results[1] ?? [];
      final rawTra = results[2] ?? [];
      final rawThsr = results[3] ?? [];

      final List<Map<String, dynamic>> combinedRaw = [
        ...rawOffStreet.map((e) => Map<String, dynamic>.from(e)),
        ...rawFreeway.map((e) => Map<String, dynamic>.from(e)),
        ...rawTra.map((e) => Map<String, dynamic>.from(e)),
        ...rawThsr.map((e) => Map<String, dynamic>.from(e)),
      ];

      /// 2. 取得 TDX 即時剩餘車位資料
      List liveRaw = await fetchParkLiveStatus(cityCode);
      Map<String, Map<String, dynamic>> liveMap = {
        for (var item in liveRaw)
          item["CarParkID"].toString(): Map<String, dynamic>.from(item),
      };

      /// 3. 工廠模型化 (轉為強型別 ParkingLot 物件，預先解析好經緯度與名稱)
      List<ParkingLot> parsedLots = combinedRaw.map((park) {
        final id = park["CarParkID"].toString();
        return ParkingLot.fromMap(park, liveMap[id]);
      }).toList();

      /// 4. 依照使用者當前位置進行距離排序
      parsedLots.sort((a, b) {
        double da = calculateApproxDistance(
          locationProvider.latitude,
          locationProvider.longitude,
          a.lat,
          a.lng,
        );
        double db = calculateApproxDistance(
          locationProvider.latitude,
          locationProvider.longitude,
          b.lat,
          b.lng,
        );
        return da.compareTo(db);
      });

      if (!mounted) return;
      setState(() {
        _allParking = parsedLots;
        _filteredStations = List.from(parsedLots);
        _isLoading = false;
        _hasLoadError = false;
      });

      /// 5. 更新地圖標記
      _loadMarkers();
    } catch (e) {
      debugPrint("Fetch data error: $e");
      if (!mounted) return;
      setState(() {
        _allParking = [];
        _filteredStations = [];
        _isLoading = false;
        _hasLoadError = true;
      });
    }
  }

  /// 批量地圖標記生成
  void _loadMarkers() {
    final Set<Marker> markerCache = _filteredStations.map((station) {
      final name = station.localizedName(
        Localizations.localeOf(context).languageCode,
      );
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.lat, station.lng),
        infoWindow: InfoWindow(title: name, snippet: station.id),
        onTap: () {
          _searchController.text = name;
          _filterStations(name);
        },
      );
    }).toSet();

    // 延後執行確保 Context 安全，並防止 build 過程觸發 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MarkerProvider>(
          context,
          listen: false,
        ).setMarkers(markerCache);
      }
    });
  }

  /// 搜尋輸入變動事件處理 (帶 250ms 防抖)
  void _onSearchInputChanged() {
    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _filterStations(_searchController.text);
      }
    });
  }

  /// 執行清單與地圖過濾
  void _filterStations(String query) {
    final cleanQuery = query.trim().toLowerCase();

    final filtered = _allParking.where((station) {
      final name = station.name.toLowerCase();
      final nameEn = station.nameEn.toLowerCase();
      final address = station.address.toLowerCase();
      return name.contains(cleanQuery) ||
          nameEn.contains(cleanQuery) ||
          address.contains(cleanQuery);
    }).toList();

    if (!mounted) return;
    setState(() {
      _filteredStations = filtered;
    });

    _loadMarkers();

    // 若搜尋結果唯有一筆，自動將地圖鏡頭移動定位
    if (filtered.length == 1) {
      final station = filtered.first;
      if (station.lat != 0.0 && station.lng != 0.0) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(station.lat, station.lng),
              zoom: 17,
            ),
          ),
        );
      }
    }
  }

  void _updatedCorrespondingID() {
    final city = cities.firstWhere(
          (c) => c.name == _currentCityNotifier.value,
      orElse: () => const CityItem(name: '全部', id: 'all'),
    );
    _correspondingIDNotifier.value = city.id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🚀 使用最新 Flutter 官方推薦 PopScope 替換已廢棄的 WillPopScope
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Provider.of<MarkerProvider>(
            context,
            listen: false,
          ).setMarkers({});
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppThemes.getCardColor(context),
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.text_497,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
          actions: [_buildCityDropdown(context)],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1A73E8).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: theme.primaryColor,
            size: 40,
          ),
        )
            : Stack(
          children: [
            // 地圖背景元件
            map(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
            // 可拖曳式滾動面板
            _buildDraggableSheet(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdown(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.15),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          value: _selectedCity,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          selectedItemBuilder: (BuildContext context) {
            return cities.map<Widget>((CityItem city) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _cityName(city),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: cities.map((CityItem city) {
            final isSelected = _selectedCity == city.name;
            return DropdownMenuItem<String>(
              value: city.name,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cityName(city),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;
            _currentCityNotifier.value = value;
            _selectedCity = value;
            _updatedCorrespondingID();
            await _fetchData();
          },
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(blurRadius: 10, color: Colors.black26),
            ],
          ),
          child: Column(
            children: [
              // 頂部拖曳指示條
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 40,
                      height: 5,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // 搜尋輸入框區域
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_139,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterStations('');
                        },
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // 停車場列表
              Expanded(
                child: _filteredStations.isEmpty
                    ? _buildEmptySearchState()
                    : ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    return _buildModernStationCard(
                      _filteredStations[index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStationCard(ParkingLot park) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final parkName = park.localizedName(
      locale,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StationDetailPage(station: park),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：標頭與剩餘狀態
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        size: 18,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parkName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: park.capacityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  park.capacityLevel,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  park.capacityTextFor(locale),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: park.capacityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 地址描述
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _localizedParkingValue(park.address),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 車位與費用資訊
                Row(
                  children: [
                    Expanded(child: _buildAvailabilityInfoWidget(park)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFareInfoWidget(
                        _localizedParkingValue(park.fareDescription),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 快捷操作按鈕
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.phone_rounded,
                        label: AppLocalizations.of(context)!.text_963,
                        color: const Color(0xFF34C759),
                        onTap: () => StationActions.makeCall(park.phone),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.directions_rounded,
                        label: AppLocalizations.of(context)!.text_964,
                        color: const Color(0xFF1A73E8),
                        onTap: () {
                          // 🚀 使用預先解析好的經緯度，完全解決原本 0.0 無法導航的瑕疵
                          StationActions.openNavigation(
                            park.lat,
                            park.lng,
                            parkName,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.share_rounded,
                        label: AppLocalizations.of(context)!.text_965,
                        color: const Color(0xFFAF52DE),
                        onTap: () => StationActions.shareStation(park.toMap()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfoWidget(ParkingLot park) {
    final l10n = AppLocalizations.of(context)!;
    if (park.totalSpaces == null || park.availableSpaces == null) {
      return Text(
        l10n.text_506,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final ratio = (park.availableSpaces! / park.totalSpaces!).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_car_rounded,
                size: 14, color: park.capacityColor),
            const SizedBox(width: 4),
            Text(
              "${park.availableSpaces} / ${park.totalSpaces}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: park.capacityColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(park.capacityColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFareInfoWidget(String fare) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              size: 14,
              color: Color(0xFFFF9500),
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.text_507,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          fare.isNotEmpty ? fare : AppLocalizations.of(context)!.text_508,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                size: 32,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasLoadError ? l10n.text_966 : l10n.text_498,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
            ),
            if (_hasLoadError) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchData,
                child: Text(l10n.text_962),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                l10n.text_499,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🟢 停車場詳細資訊頁面 (使用強型別 ParkingLot 避免 null crash)
class StationDetailPage extends StatelessWidget {
  final ParkingLot station;

  const StationDetailPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final stationName = station.localizedName(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: AppThemes.getCardColor(context),
        elevation: 0,
        title: Text(
          stationName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 18,
                color: Color(0xFF1A73E8),
              ),
            ),
            onPressed: () => StationActions.shareStation(station.toMap()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(context, stationName),
            _buildInfoSection(context, l10n.text_511, [
              _buildInfoItem(
                l10n,
                Icons.qr_code_rounded,
                l10n.text_512,
                station.id,
              ),
              _buildInfoItem(
                l10n,
                Icons.location_on_rounded,
                l10n.text_513,
                station.address == '無地址資訊' ? l10n.text_501 : station.address,
              ),
              _buildInfoItem(
                l10n,
                Icons.phone_rounded,
                l10n.text_514,
                station.phone,
              ),
            ]),
            _buildInfoSection(context, l10n.text_515, [
              _buildInfoItem(
                l10n,
                Icons.monetization_on_rounded,
                l10n.text_516,
                station.fareDescription.isEmpty ||
                    station.fareDescription == '無費率資訊'
                    ? l10n.text_508
                    : station.fareDescription,
              ),
              _buildInfoItem(
                l10n,
                Icons.credit_card_rounded,
                l10n.text_517,
                ParkingTypeHelper.getChargeTypes(
                  station.chargeTypes,
                  english: isEnglish,
                ).join(', '),
              ),
            ]),
            _buildInfoSection(context, l10n.text_518, [
              _buildInfoItem(
                l10n,
                Icons.local_parking_rounded,
                l10n.text_519,
                ParkingTypeHelper.getCarParkType(
                  station.carParkType,
                  english: isEnglish,
                ),
              ),
              _buildInfoItem(
                l10n,
                Icons.description_rounded,
                l10n.text_520,
                station.description == '無營運描述'
                    ? l10n.text_508
                    : station.description,
              ),
            ]),
            _buildInfoSection(context, l10n.text_521, [
              _buildBooleanItem(
                l10n,
                Icons.access_time_rounded,
                l10n.text_522,
                station.isFreeOutOfHours,
              ),
              _buildBooleanItem(
                l10n,
                Icons.ev_station,
                l10n.text_523,
                station.hasEV,
              ),
              _buildBooleanItem(
                l10n,
                Icons.nightlight_rounded,
                l10n.text_524,
                station.overnightPermitted,
              ),
              _buildBooleanItem(
                l10n,
                Icons.sensors_rounded,
                l10n.text_525,
                station.vehicleDetection,
              ),
              _buildBooleanItem(
                l10n,
                Icons.wheelchair_pickup,
                l10n.text_526,
                station.wheelchairAccessible,
              ),
            ]),
            _buildInfoSection(
              context,
              l10n.text_527,
              [_buildLocationItem(context, stationName)],
            ),
            _buildActionButtons(stationName, l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, String stationName) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stationName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (station.totalSpaces != null && station.availableSpaces != null)
            _buildAvailabilityProgress(AppLocalizations.of(context)!)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(l10n.text_529,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityProgress(AppLocalizations l10n) {
    final ratio =
    (station.availableSpaces! / station.totalSpaces!).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.text_530,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: station.capacityColor,
              ),
            ),
            Text(
              '${station.availableSpaces} / ${station.totalSpaces}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: station.capacityColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(station.capacityColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      AppLocalizations l10n,
      IconData icon,
      String title,
      dynamic value,
      ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString().isNotEmpty == true
                      ? value.toString()
                      : l10n.text_508,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanItem(
      AppLocalizations l10n,
      IconData icon,
      String title,
      bool value,
      ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF34C759).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value ? l10n.text_531 : l10n.text_532,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF34C759) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(BuildContext context, String stationName) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.map_rounded, size: 18, color: Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.text_533,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? "Latitude: ${station.lat}, Longitude: ${station.lng}"
                      : "緯度: ${station.lat}, 經度: ${station.lng}",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
            const Icon(Icons.navigation_rounded, color: Color(0xFF1A73E8)),
            onPressed: () => StationActions.openNavigation(
              station.lat,
              station.lng,
              stationName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String stationName, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone_rounded),
              label: Text(l10n.text_534),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => StationActions.makeCall(station.phone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_rounded),
              label: Text(l10n.text_535),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => StationActions.openNavigation(
                station.lat,
                station.lng,
                stationName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParkingTypeHelper {
  static String getCarParkType(dynamic type, {bool english = false}) {
    final Map<int, String> typeMap = english
        ? const {
      1: 'Flat parking',
      2: 'Multi-storey parking',
      3: 'Underground parking',
      4: 'Parking garage',
      5: 'Mechanical parking',
      6: 'Multiple parking types',
      254: 'Other',
      255: 'Unknown',
    }
        : const {
      1: '平面',
      2: '立體',
      3: '地下',
      4: '立體停車塔',
      5: '立體機械式',
      6: '涵蓋2種以上',
      254: '其他',
      255: '未知',
    };
    int t = _parseSingle(type);
    return typeMap[t] ?? (english ? 'Unknown' : '未知');
  }

  static List<String> getChargeTypes(dynamic types, {bool english = false}) {
    final Map<int, String> chargeMap = english
        ? const {
      1: 'Hourly',
      2: 'Per entry',
      3: 'Monthly',
      4: 'Free',
      254: 'Other',
      255: 'Unknown',
    }
        : const {
      1: '計時',
      2: '計次',
      3: '月租',
      4: '免費',
      254: '其他',
      255: '未知',
    };
    return _parseList(
      types,
      chargeMap,
      noData: english ? 'No data' : '無資料',
      unknown: english ? 'Unknown' : '未知',
    );
  }

  static int _parseSingle(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _parseList(
      dynamic value,
      Map<int, String> map, {
        required String noData,
        required String unknown,
      }) {
    if (value == null) return [noData];
    List<int> list = [];
    if (value is List) {
      list = value.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    } else if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          list = parsed.map((e) => int.tryParse(e.toString()) ?? 0).toList();
        } else {
          list = [int.tryParse(parsed.toString()) ?? 0];
        }
      } catch (_) {
        list = [int.tryParse(value) ?? 0];
      }
    } else if (value is int) {
      list = [value];
    }
    return list.map((e) => map[e] ?? unknown).toList();
  }
}
