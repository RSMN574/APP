
import 'dart:ui';

import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Const/regularClass.dart';
import '../database/EV_station/EV_station.dart';
import '../utils/convert.dart';
import '../widget/map.dart';

class EVStation extends StatefulWidget {
  const EVStation({super.key});

  @override
  State<EVStation> createState() => _EVStationState();
}

class _EVStationState extends State<EVStation> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredStations = [];
  List<dynamic>? allEV=[]; // 所有公車資料
  bool _isLoading = true;
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _fetchData();
  }
// 在 class 內宣告
  final FocusNode _searchFocusNode = FocusNode();
  Future<void> _fetchData() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    try {
      List<Map<String, dynamic>> data =
          await mysqlSelect("SELECT * FROM EV_Charging.EV_station;")?? [];
      List<Map<String, dynamic>> findNearestStations(
          List<dynamic> stations,
          double userLat,
          double userLon, {
            int count = 5,
          }) {
        List<Map<String, dynamic>> sortedStations = List.from(stations)
          ..sort((a, b) {
            double distanceA = calculateEuclideanDistance(
              userLat,
              userLon,
              double.parse( a["PositionLat"]),
              double.parse( a["PositionLon"]),
            );
            double distanceB = calculateEuclideanDistance(
              userLat,
              userLon,
              double.parse ( b["PositionLat"]),
              double.parse(b["PositionLon"]),
            );
            return distanceA.compareTo(distanceB);
          });

        return sortedStations.toList();
      }

// 呼叫函式
      List<dynamic> nearestStations = findNearestStations(
        data,
        locationProvider.latitude,locationProvider.longitude,

        count: 5,
      );
      setState(() {
        allEV = nearestStations;
        _filteredStations = List.from(nearestStations); // 初始時顯示所有數據
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        allEV = [];
        _filteredStations = [];
        _isLoading = false;
      });
    }
  }


  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }


  void _filterStations(String query) {
    query = query.trim().toLowerCase();
    // if (query.isEmpty) {
    //   setState(() => _filteredStations = List.from(allEV));
    //   return;
    // }

    final filtered = allEV?.where((station) {
      final name = station['StationNameZh_tw']?.toString().toLowerCase() ?? '';
      final address = station['LocationCityRoadRoad']?.toString().toLowerCase() ?? '';
      return name.contains(query) || address.contains(query);
    }).toList();

    setState(() => _filteredStations = filtered!);
  }


  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('充電樁資訊'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // 地圖元件放在背景中
          map(),
          // DraggableScrollableSheet 實現可拖曳、調整高度的面板
          DraggableScrollableSheet(
            initialChildSize: 0.3, // 初始高度佔螢幕比例
            minChildSize: 0.3, // 最小高度
            maxChildSize: 0.8, // 最大高度
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 拖曳指示條，帶有模糊效果
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            width: 40,
                            height: 5,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    // 搜尋輸入框
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜尋站點名稱或地址',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black54,
                          ),
                        ),
                        onChanged: _filterStations,
                      ),
                    ),
                    // 站點列表，使用 DraggableScrollableSheet 提供的 scrollController
                    Expanded(
                      child: _buildStationList(
                        _filteredStations,
                        scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }



// 分離的列表建構方法
  Widget _buildStationList(List<dynamic> nearestStations ,scrollController) {
    if (nearestStations.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      controller: scrollController, // 確保使用提供的controller
      physics: const BouncingScrollPhysics(),
      itemCount: nearestStations.length,
      itemBuilder: (context, index) {
        final station = nearestStations[index];
        return _buildModernStationCard(station);
      },
    );
  }
// 空狀態顯示
  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Icon(Icons.hourglass_empty),
          const SizedBox(height: 24),
          Text(
            '找不到符合條件的充電站',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請嘗試不同的搜尋關鍵字',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
/// 現代化充電站卡片
  Widget _buildModernStationCard(Map<String, dynamic> station) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () =>  Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StationDetailPage(station: station),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[50]!.withOpacity(0.6),
                Colors.blueGrey[50]!.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green[100]!.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題列
                Row(
                  children: [
                    // _buildStatusIndicator(station),
                    // const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStationTitle(station),
                          const SizedBox(height: 4),
                          _buildStationSubtitle(station),
                        ],
                      ),
                    ),
                    _buildNavigationArrow(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernInfoGrid(station),
                const SizedBox(height: 12),
                _buildActionChips(station),
              ],
            ),
          ),
        ),
      ),
    );
  }

// 充電站標題
  Widget _buildStationTitle(Map<String, dynamic> station) {
    return Row(
      children: [
        Icon(Icons.ev_station, size: 20, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            station['StationNameZh_tw'] ?? '未命名充電站',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.green[900],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

// 充電站副標題
  Widget _buildStationSubtitle(Map<String, dynamic> station) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${station['LocationCityRoadCity']} ${station['LocationCityRoadTown']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
  // 狀態指示器
  Widget _buildStatusIndicator(Map<String, dynamic> station) {
    final isAvailable = station['Available'] == 'true';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: isAvailable ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? '營運中' : '暫停服務',
            style: TextStyle(
              color: isAvailable ? Colors.green[700] : Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// 現代化資訊網格
  Widget _buildModernInfoGrid(Map<String, dynamic> station) {

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGridItem(Icons.bolt, '充電費率', station['ChargingRate']),
            VerticalDivider(width: 1, color: Colors.grey[200]),
            _buildGridItem(Icons.local_parking, '停車費率', station['ParkingRate']),
            // VerticalDivider(width: 1, color: Colors.grey[200]),
            // _buildGridItem(Icons.speed, '最大功率', '${station['MaxPower']} kW'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title, String value) {
    // 限制文字最大長度
    final maxLength = 10; // 最大顯示字數
    final truncatedValue = value.length > maxLength
        ? '${value.substring(0, maxLength)}...' // 超出部分顯示省略號
        : value ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圖示
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(height: 8),
          // 值（充電費率）
          Tooltip(
            message: value, // 懸停時顯示完整內容
            child: Text(
              truncatedValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // 文字過長時顯示省略號
              maxLines: 1, // 限制為一行
            ),
          ),
          const SizedBox(height: 4),
          // 標題
          Tooltip(
            message: title, // 懸停時顯示完整內容
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // 文字過長時顯示省略號
              maxLines: 1, // 限制為一行
            ),
          ),
        ],
      ),
    );
  }

// 操作按鈕區
  Widget _buildActionChips(Map<String, dynamic> station) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (station['Telephone'] != null)
          _buildActionButton(
            icon: Icons.phone_in_talk_rounded,
            label: '聯絡',
            color: Colors.blue[100]!,
            onTap: () => print(station) //_callStation(station),
          ),
        _buildActionButton(
          icon: Icons.directions_rounded,
          label: '導航',
          color: Colors.green[100]!,
          onTap: () =>  print(station) //_navigateToStation(station),
        ),
        _buildActionButton(
          icon: Icons.share_rounded,
          label: '分享',
          color: Colors.purple[100]!,
          onTap: () =>  print(station) //_shareStation(station),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 導航箭頭
  Widget _buildNavigationArrow() {
    return RotationTransition(
      turns: _searchFocusNode.hasFocus
          ? const AlwaysStoppedAnimation(0.25)
          : const AlwaysStoppedAnimation(0.0),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.green[400],
        size: 20,
      ),
    );
  }
}
class StationDetailPage extends StatefulWidget {
  final Map<String, dynamic> station;

  const StationDetailPage({Key? key, required this.station}) : super(key: key);

  @override
  _StationDetailPageState createState() => _StationDetailPageState();
}

class _StationDetailPageState extends State<StationDetailPage> {
  // 新增合併資料結構
  List<MergedConnector> _mergedConnectors = [];

  @override
  void initState() {
    super.initState();
    _fetchChargingPoints().then((points) {
      _mergeConnectors(points);
    });
  }

  // 合併充電接口核心邏輯
  Future<void> _mergeConnectors(List<Map<String, dynamic>> points) async {
    var connectorMap = <String, MergedConnector>{};

    for (final point in points) {
      for (int i = 0; i < 3; i++) {
        final type = point['Connectors${i}Type'];
        if (type == null) continue;

        // 建立合併識別碼
        final key = [
          type,
          point['Connectors${i}Type'],
          point['ChargingRate'],
          point['Floor'],
        ].join('|');

        final connector = MergedConnector(
          type: type,
          power: point['Connectors${i}Type'],
          rate: point['ChargingRate'],
          floor: point['Floor'],
          quantity: int.tryParse(point['Connectors${i}Quantity'] ?? '0') ?? 0,
          points: [point['ChargingPointID']],
        );

        if (connectorMap.containsKey(key)) {
          connectorMap[key] = connectorMap[key]!.mergeWith(connector);
        } else {
          connectorMap[key] = connector;
        }
      }
    }
    List<dynamic> connectorLiveStatus=(await fetchConnectorLiveStatus(widget.station["StationID"]));


    final mergedConnectors = connectorLiveStatus.map((status) {
      final connectorType = status["ConnectorType"];

      // 若 `connectorType` 無效，則跳過
      // if (connectorType == null || !connectorMap.containsKey(connectorType)) {
      //   return null;
      // }
      print("connectorMap Keys: ${connectorMap.keys.toList()}");
      print("Looking for ConnectorType: '$connectorType'");

// 使用模糊匹配查找
      final matchedItem = connectorMap.entries.firstWhere(
            (entry) => entry.key.startsWith("$connectorType|"),
          orElse: () => MapEntry("", MergedConnector(
            type: "",
            power: "",
            rate: "",
            floor: "",
            quantity: 0,
            points: [],
            ConnectorStatus: (status["ConnectorStatus"] ?? 0).toString(),
          )), // 确保返回一个 MergedConnector
      ).value;

      print("Matched Connector: $matchedItem");


      return MergedConnector(
        type: matchedItem.type, // 使用 matchedItem 的 type
        power: matchedItem.power, // 可能需要转换格式
        rate: matchedItem.rate,
        floor: matchedItem.floor,
        quantity: matchedItem.quantity,
        points: matchedItem.points,
        ConnectorStatus: (status["ConnectorStatus"])  .toString(),

        // 來自 `connectorLiveStatus`
      );
    }).whereType<MergedConnector>().toList(); // 過濾掉 null 項

// 輸出結果
    print(mergedConnectors);
if(mergedConnectors.isNotEmpty){
  setState(() {
    _mergedConnectors = mergedConnectors;
  });
}else{
  setState(() {
    _mergedConnectors = connectorMap.values.toList();
  });
}

  }

  Future<List<Map<String, dynamic>>> _fetchChargingPoints() async {
    try {
      List<Map<String, dynamic>> chargingPoint = await mysqlSelect(
        "SELECT * FROM EV_Charging.EV_ChargingPoint WHERE StationID='${widget.station["StationID"]}';",
      ) ??
          [];


      return chargingPoint;
    } catch (e) {
      print("錯誤: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station['StationNameZh_tw'] ?? '充電站詳情',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[800]!, Colors.green[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!.withOpacity(0.3),
              Colors.green[50]!.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _mergedConnectors.isEmpty
            ? _buildEmptyState()
            : CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildModernConnectorCard(_mergedConnectors[index]),
                  childCount: _mergedConnectors.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernConnectorCard(MergedConnector connector) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            leading: _buildConnectorBadge(connector.type),
            title: _buildConnectorTitle(connector),
            subtitle: _buildConnectorSubtitle(connector),
            trailing: _buildStatusIndicator(connector.points),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  children: [
                    _buildInfoGrid(connector),
                    const SizedBox(height: 16),
                    _buildDistributionList(connector.points),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectorBadge(String type) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getColor(type).withOpacity(0.2),
            _getColor(type).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          _getIcon(type),
          size: 28,
          color: _getColor(type),
        ),
      ),
    );
  }

  Widget _buildConnectorTitle(MergedConnector connector) {

    final status = _getConnectorStatus(int.tryParse(connector.ConnectorStatus.toString()) ?? 0);
    final statusText = status['text'];
    final statusColor = status['color'];
    final statusIcon = status['icon'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 狀態圖示
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                statusIcon,
                key: ValueKey(statusIcon), // 確保動畫觸發
                size: 18,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            // 標題文字
            Text(
              _getTypeName(connector.type),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 狀態標籤
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 功率和費率
        Text(
          '${connector.power}kW • ${connector.rate}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

// 獲取狀態資訊
  Map<String, dynamic> _getConnectorStatus(int status) {
    switch (status) {
      case 1:
        return {
          'text': '可用',
          'color': Colors.green[700]!,
          'icon': Icons.check_circle,
        };
      case 2:
        return {
          'text': '已滿',
          'color': Colors.orange[700]!,
          'icon': Icons.build,
        };
      case 3:
        return {
          'text': '維護中',
          'color': Colors.blue[700]!,
          'icon': Icons.bolt,
        };
      default:
        return {
          'text': '未知',
          'color': Colors.grey[700]!,
          'icon': Icons.error_outline,
        };
    }
  }

  Widget _buildConnectorSubtitle(MergedConnector connector) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildInfoChip(
            icon: Icons.layers,
            label: connector.floor,
            color: Colors.blue[100]!,
          ),
          _buildInfoChip(
            icon: Icons.electrical_services,
            label: '${connector.quantity} 個接口',
            color: Colors.green[100]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(List<String> points) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${points.length} 個分佈點',
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.expand_more,
          color: Colors.grey[500],
          size: 20,
        ),
      ],
    );
  }

  Widget _buildInfoGrid(MergedConnector connector) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGridItem('最大功率', '${connector.power}kW', Icons.bolt),
            const VerticalDivider(thickness: 1, width: 32),
            _buildGridItem('充電費率', connector.rate, Icons.attach_money),
            const VerticalDivider(thickness: 1, width: 32),
            _buildGridItem('可用接口', '${connector.quantity}', Icons.power),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(height: 8),
        Text(value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionList(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('分佈位置',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_pin, size: 18, color: Colors.red[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Text('充電點 ID: $point',
                    style: TextStyle(color: Colors.grey[700])),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  // ==== 新增類型名稱映射方法 ====
  String _getTypeName(String type) {
    const typeNames = {
      '1': 'Type 1 (J1772)',
      '2': 'Type 2 (Mennekes)',
      '3': 'CHAdeMO',
      '4': 'CCS1',
      '5': 'CCS2',
      '6': 'Tesla Supercharger',
    };
    return typeNames[type] ?? '未知類型';
  }

  // ==== 新增圖示映射方法 ====
  IconData _getIcon(String type) {
    const icons = {
      '1': Icons.ev_station, // Type 1
      '2': Icons.bolt,       // Type 2
      '3': Icons.flash_on,   // CHAdeMO
      '4': Icons.electric_car, // CCS1
      '5': Icons.electric_car, // CCS2
      '6': Icons.battery_charging_full, // Tesla
    };
    return icons[type] ?? Icons.power;
  }

  // ==== 新增顏色映射方法 ====
  Color _getColor(String type) {
    const colors = {
      '1': Colors.blue,      // Type 1
      '2': Colors.green,     // Type 2
      '3': Colors.orange,    // CHAdeMO
      '4': Colors.purple,    // CCS1
      '5': Colors.indigo,    // CCS2
      '6': Colors.red,       // Tesla
    };
    return colors[type] ?? Colors.grey;
  }

  // ==== 空狀態顯示 ====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ev_station, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '沒有可用的充電接口',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// **通用資訊行**


}
// ==== 資料模型 ====
class MergedConnector {
  final String type;
  final String power;
  final String rate;
  final String floor;
  final int quantity;
  final List<String> points;

final String? ConnectorStatus;
  MergedConnector({
    required this.type,
    required this.power,
    required this.rate,
    required this.floor,
    required this.quantity,
    required this.points,

    this.ConnectorStatus
  });

  MergedConnector mergeWith(MergedConnector other) {
    return MergedConnector(
      type: type,
      power: power,
      rate: rate,
      floor: floor,
      quantity: quantity + other.quantity,
      points: [...points, ...other.points],

        ConnectorStatus:ConnectorStatus

    );
  }
  get _type => type;

}