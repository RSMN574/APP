import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


import 'package:com.rsmn574.app/features/airport/state/airport_provider.dart';
import 'package:com.rsmn574.app/features/airport/model/airport_model.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

final PageController pageController = PageController();

class Plane extends StatefulWidget {
  const Plane({super.key});

  @override
  State<Plane> createState() => _PlaneState();
}

class _PlaneState extends State<Plane> {
  final TextEditingController _flightNumberController = TextEditingController();

  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';

  late final List<String> tabs = [
    AppLocalizations.of(context)!.text_747,
    AppLocalizations.of(context)!.text_748,
    AppLocalizations.of(context)!.text_749,
    AppLocalizations.of(context)!.text_750,
  ];

  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  int _current = 0;

  late final List<Map<String, dynamic>> services = [
    {'icon': Icons.local_taxi, 'label': AppLocalizations.of(context)!.text_751},
    {'icon': Icons.local_dining, 'label': AppLocalizations.of(context)!.text_752},
    {'icon': Icons.restaurant, 'label': AppLocalizations.of(context)!.text_753},
    {'icon': Icons.airplane_ticket, 'label': AppLocalizations.of(context)!.text_754},
    {'icon': Icons.security, 'label': AppLocalizations.of(context)!.text_755},
    {'icon': Icons.luggage, 'label': AppLocalizations.of(context)!.text_656},
  ];

  String selectedAirport = "TPE";

  @override
  void dispose() {
    _flightNumberController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  // ==========================================
  // l10n 輔助方法
  // ==========================================
  String _localizedAirportName(AirportData airport) {
    final l10n = AppLocalizations.of(context)!;
    switch (airport.iataCode) {
      case 'TPE': return l10n.airport_name_TPE;
      case 'TSA': return l10n.airport_name_TSA;
      case 'RMQ': return l10n.airport_name_RMQ;
      case 'KHH': return l10n.airport_name_KHH;
      case 'TNN': return l10n.airport_name_TNN;
      case 'HUN': return l10n.airport_name_HUN;
      case 'TTT': return l10n.airport_name_TTT;
      case 'CYI': return l10n.airport_name_CYI;
      case 'KNH': return l10n.airport_name_KNH;
      case 'MZG': return l10n.airport_name_MZG;
      case 'MFK': return l10n.airport_name_MFK;
      case 'LZN': return l10n.airport_name_LZN;
      case 'KYD': return l10n.airport_name_KYD;
      case 'GNI': return l10n.airport_name_GNI;
      default: return airport.name;
    }
  }

  String _localizedAirportNameByCode(String code) {
    final provider = context.read<AirportProvider>();
    final airport = provider.byCode(code);
    if (airport != null) return _localizedAirportName(airport);
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'TPE': return l10n.airport_name_TPE;
      case 'TSA': return l10n.airport_name_TSA;
      case 'RMQ': return l10n.airport_name_RMQ;
      case 'KHH': return l10n.airport_name_KHH;
      case 'TNN': return l10n.airport_name_TNN;
      case 'HUN': return l10n.airport_name_HUN;
      case 'TTT': return l10n.airport_name_TTT;
      case 'CYI': return l10n.airport_name_CYI;
      case 'KNH': return l10n.airport_name_KNH;
      case 'MZG': return l10n.airport_name_MZG;
      case 'MFK': return l10n.airport_name_MFK;
      case 'LZN': return l10n.airport_name_LZN;
      case 'KYD': return l10n.airport_name_KYD;
      case 'GNI': return l10n.airport_name_GNI;
      default: return code;
    }
  }

  String _localizedAirportText(String value) {
    final l10n = AppLocalizations.of(context)!;
    final map = {
      '機場捷運': l10n.airport_transport_airport_mrt,
      '直達台北車站，約35分鐘': l10n.airport_transport_direct_taipei,
      '客運巴士': l10n.airport_transport_intercity_bus,
      '多條路線通往全台各地': l10n.airport_transport_multiple_routes,
      '計程車': l10n.airport_transport_taxi,
      '24小時排班服務': l10n.airport_transport_taxi_24h,
      '租車服務': l10n.airport_transport_car_rental,
      '各大租車公司進駐': l10n.airport_transport_major_rental,

      '捷運文湖線': l10n.airport_transport_airport_mrt,
      '松山機場站，直達市區': l10n.airport_transport_direct_taipei,
      '公車': l10n.airport_transport_intercity_bus,
      '多線公車可達': l10n.airport_transport_multiple_routes,
      '排班服務': l10n.airport_transport_taxi_24h,
      '機場外有站點': l10n.airport_transport_major_rental,
      '多線公車可達市區': l10n.airport_transport_multiple_routes,
      '機場內提供': l10n.airport_transport_major_rental,
      '高雄捷運紅線': l10n.airport_transport_airport_mrt,
      '直達機場站（R4）': l10n.airport_transport_direct_taipei,
      '客運/計程車': l10n.airport_transport_intercity_bus,
      '多線可達市區': l10n.airport_transport_multiple_routes,
      '航站提供': l10n.airport_transport_major_rental,
      '可達台南市區': l10n.airport_transport_multiple_routes,
      '機場外可搭乘': l10n.airport_transport_taxi_24h,
      '可達花蓮市': l10n.airport_transport_multiple_routes,
      '可達台東市': l10n.airport_transport_multiple_routes,
      '機場外服務': l10n.airport_transport_taxi_24h,
      '可達嘉義市區 / 火車站': l10n.airport_transport_multiple_routes,
      '鄉內路線可達': l10n.airport_transport_multiple_routes,
      '連接澎湖本島各地': l10n.airport_transport_multiple_routes,
      '機場外可搭': l10n.airport_transport_taxi_24h,

      '免稅商店': l10n.airport_service_duty_free,
      '貴賓室': l10n.airport_service_lounge,
      '餐飲服務': l10n.airport_service_dining,
      '免費WiFi': l10n.airport_service_wifi,
      'Wi-Fi': l10n.airport_service_wifi,
      'WiFi': l10n.airport_service_wifi,
      '貨幣兌換': l10n.airport_service_currency_exchange,
      '行李寄存': l10n.airport_service_luggage_storage,
      '祈禱室': l10n.airport_service_prayer_room,
      '育嬰室': l10n.airport_service_nursery,
      '哺乳室': l10n.airport_service_nursing_room,
      '便利商店': l10n.airport_service_convenience_store,
      '觀景台': l10n.airport_service_observation_deck,

      '機場警察': l10n.airport_emergency_airport_police,
      '醫療中心': l10n.airport_emergency_medical_center,
      '遺失物協尋': l10n.airport_emergency_lost_and_found,
      '機場服務台': l10n.airport_emergency_info_desk,
      '醫療協助': l10n.airport_emergency_medical_assistance,
      '警察局': l10n.airport_emergency_police_station,
      '服務中心': l10n.airport_emergency_service_center,
      '醫療站': l10n.airport_emergency_medical_station,
    };
    return map[value] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AirportProvider>();

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            '${_localizedAirportNameByCode(selectedAirport)} ${AppLocalizations.of(context)!.text_762}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A73E8).withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: selectedAirport,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF1A73E8)),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _buildAirportDropdownItems(provider),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedAirport = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabBar(),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFD)),
          child: Column(
            children: [
              Expanded(child: _buildPageView()),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildAirportDropdownItems(
      AirportProvider provider) {
    final codes = <String>[
      'TPE', 'TSA', 'KHH', 'RMQ',
      'TNN', 'HUN', 'TTT', 'CYI',
      'KNH', 'MZG', 'MFK', 'LZN',
      'KYD', 'GNI',
    ];

    return codes.map((code) {
      final isSelected = selectedAirport == code;
      return DropdownMenuItem<String>(
        value: code,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF3FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.flight_takeoff_rounded,
                size: 16,
                color: const Color(0xFF1A73E8).withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(_localizedAirportNameByCode(code)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTabBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = _current == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _current = index);
          pageController.animateToPage(
            _current,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 100,
          height: 76,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF1A73E8).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: isSelected
                ? Border.all(
              color: const Color(0xFF1A73E8).withOpacity(0.2),
              width: 1.5,
            )
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Center(
            child: Text(
              tabs[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A73E8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemCount: tabs.length,
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildAirportInfoTab();
          case 1:
            return _buildArrivalTab();
          case 2:
            return _buildDepartureTab();
          case 3:
            return _buildSearchTab();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildArrivalTab() {
    return FutureBuilder<List<dynamic>>(
      future: context.read<AirportProvider>().arrivals(selectedAirport),
      builder: (context, snapshot) {
        return _buildFlightList(snapshot, 'Arrival');
      },
    );
  }

  // ==========================================
  // 機場資訊 Tab（使用 API 資料）
  // ==========================================
  Widget _buildAirportInfoTab() {
    final provider = context.watch<AirportProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context)!.airport_load_failed}：${provider.error}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadAirports(),
              child: Text(AppLocalizations.of(context)!.airport_retry),
            ),
          ],
        ),
      );
    }

    final airport = provider.byCode(selectedAirport) ??
        provider.byCode('TPE') ??
        provider.all.first;

    final airportName = _localizedAirportName(airport);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: l10n.airport_overview_title(airportName),
            content: l10n.airport_overview_content(
              airport.iataCode,
              airport.area.toStringAsFixed(0),
              airport.terminals,
              airport.annualPassengers.toString(),
              airport.phone,
            ),
            color: airport.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildTransportationCard(airport),
          const SizedBox(height: 16),
          _buildServicesCard(airport),
          const SizedBox(height: 16),
          _buildEmergencyCard(airport),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportationCard(AirportData airport) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_transit_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.text_767,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...airport.transport.map((transport) => Column(
                  children: [
                    _buildTransportItem(
                      _localizedAirportText(transport.title),
                      _localizedAirportText(transport.subtitle),
                      transport.icon,
                      airport.primaryColor,
                    ),
                    if (transport != airport.transport.last)
                      const SizedBox(height: 12),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportItem(
      String title, String subtitle, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesCard(AirportData airport) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.text_769,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: airport.services
                  .map((service) => _buildServiceChip(
                _localizedAirportText(service.label),
                service.icon,
                airport.primaryColor,
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(AirportData airport) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.text_770,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...airport.emergencyContacts.entries.map((entry) => Column(
                  children: [
                    _buildEmergencyItem(
                      _localizedAirportText(entry.key),
                      entry.value,
                      Icons.phone_rounded,
                      airport.primaryColor,
                    ),
                    if (entry.key !=
                        airport.emergencyContacts.entries.last.key)
                      const SizedBox(height: 12),
                  ],
                )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: airport.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: airport.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    l10n.airport_emergency_info(airport.phone),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(
      String title, String phone, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.phone_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartureTab() {
    return FutureBuilder<List<dynamic>>(
      future: context.read<AirportProvider>().departures(selectedAirport),
      builder: (context, snapshot) {
        return _buildFlightList(snapshot, 'Departure');
      },
    );
  }

  Widget _buildFlightList(AsyncSnapshot<List<dynamic>> snapshot, String type) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Text(
          _isEnglish
              ? 'Unable to load flight information. Please try again later.'
              : '資料載入失敗，請稍後再試。',
        ),
      );
    }
    final flights = snapshot.data ?? [];
    return FlightDashboard(flights: flights, type: type);
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 24),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: Color(0xFF1A73E8), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.text_771,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _flightNumberController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_772,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    onSubmitted: (value) => _searchFlight(value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _searchFlight(_flightNumberController.text),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.text_773,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _searchFlight(String number) {
    if (number.isEmpty) return;
    _searchQuery.value = number.trim();
  }

  Map<String, String> _parseFlightNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final match = RegExp(r'^([A-Z]{1,3})(\d{1,4})$').firstMatch(cleaned);
    return {
      'AirlineID': match?.group(1) ?? '',
      'FlightNumber': match?.group(2) ?? cleaned,
    };
  }

  Widget _buildSearchResults() {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, input, _) {
        if (input.isEmpty) return _buildEmptySearchState();

        final flightInfo = _parseFlightNumber(input);
        final airlineId = flightInfo['AirlineID']!;
        final flightNumber = flightInfo['FlightNumber']!;
        final formattedFlightNumber =
        airlineId.isNotEmpty ? '$airlineId $flightNumber' : flightNumber;

        if (input != formattedFlightNumber.replaceAll(' ', '')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEnglish
                    ? 'Formatted automatically: $formattedFlightNumber'
                    : '已自動格式化: $formattedFlightNumber'),
                backgroundColor: const Color(0xFF1A73E8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          });
        }

        return FutureBuilder<List<dynamic>>(
          future: context
              .read<AirportProvider>()
              .flight(airlineId, flightNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyView();
            }
            return FlightInfoCard(flight: snapshot.data![0]);
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A73E8).withOpacity(0.1),
                  const Color(0xFF1A73E8).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.airplane_ticket_rounded,
                size: 50, color: Color(0xFF1A73E8)),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.text_774,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.text_775,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isEnglish
                  ? 'Examples: CI123, BR196, JL809'
                  : '範例：CI123, BR196, JL809',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_776,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A73E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: Color(0xFFFF3B30)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_777,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.airline_stops_rounded,
              size: 40, color: Color(0xFFFF9500)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_778,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.text_779,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FlightDashboard
// ==========================================
class FlightDashboard extends StatefulWidget {
  final String type;
  final List<dynamic> flights;

  const FlightDashboard({
    super.key,
    required this.flights,
    required this.type,
  });

  @override
  State<FlightDashboard> createState() => _FlightDashboardState();
}

class _FlightDashboardState extends State<FlightDashboard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.flights.length / 10).ceil();
    final pageFlights =
    widget.flights.skip(_currentPage * 10).take(10).toList();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              const SizedBox(height: 6),
              ...pageFlights.map((flight) => _buildFlightCard(flight)),
              if (pageFlights.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppLocalizations.of(context)!.text_780,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 0 ? const Color(0xFF1A73E8) : Colors.grey,
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Page ${_currentPage + 1} of $totalPages'
                  : '第 ${_currentPage + 1} 頁 / 共 $totalPages 頁',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < totalPages - 1
                ? const Color(0xFF1A73E8)
                : Colors.grey,
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            widget.type == "Departure"
                ? Icons.flight_takeoff
                : Icons.flight_land,
            color: const Color(0xFF1A73E8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.type == "Departure"
                  ? AppLocalizations.of(context)!.text_749
                  : AppLocalizations.of(context)!.text_748,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final delayMinutes = _calculateDelayMinutes(flight);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlightHeader(flight),
            const Divider(height: 12, thickness: 0.8),
            _buildFlightDetails(flight, delayMinutes),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightHeader(Map<String, dynamic> flight) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.airplanemode_active,
            color: Color(0xFF1A73E8),
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${flight['AirlineID'] ?? ''}${flight['FlightNumber'] ?? ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              flight['IsCargo'] == 'true'
                  ? AppLocalizations.of(context)!.text_781
                  : AppLocalizations.of(context)!.text_782,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusIndicator(
          widget.type == 'Departure'
              ? flight['DepartureRemark']
              : flight['ArrivalRemark'],
        ),
      ],
    );
  }

  Widget _buildFlightDetails(Map<String, dynamic> flight, int delayMinutes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeItem(
            AppLocalizations.of(context)!.text_783,
            widget.type == 'Departure'
                ? flight['ScheduleDepartureTime']
                : flight['ScheduleArrivalTime'],
          ),
          _buildTimeItem(
            AppLocalizations.of(context)!.text_784,
            widget.type == 'Departure'
                ? flight['ActualDepartureTime']
                : flight['ActualArrivalTime'],
            isDelayed: delayMinutes > 0,
          ),
          _buildDelayItem(delayMinutes),
          _buildInfoItem(
            AppLocalizations.of(context)!.text_785,
            flight['Terminal'] ?? '--',
          ),
          if (!(flight['IsCargo'] ?? false))
            _buildInfoItem(
              AppLocalizations.of(context)!.text_786,
              flight['BaggageClaim'] ?? '--',
            ),
          _buildInfoItem(
            AppLocalizations.of(context)!.text_787,
            flight['Gate'] ?? '--',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String? time, {bool isDelayed = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 3),
        Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDelayed ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDelayItem(int minutes) {
    final Color textColor = minutes > 0
        ? Colors.red
        : minutes < 0
        ? Colors.green
        : Colors.grey[700]!;

    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.text_788,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${minutes > 0 ? '+' : ''}$minutes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String? status) {
    final s = status ?? '';
    final indicatorStyle = _getStatusStyle(s);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: indicatorStyle['backgroundColor'] as Color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorStyle['borderColor'] as Color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorStyle['icon'] as IconData,
            size: 10,
            color: indicatorStyle['textColor'] as Color,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              s,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: indicatorStyle['textColor'] as Color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    if (status.contains('DEPARTED') || status.contains('出發')) {
      return {
        'icon': Icons.flight_takeoff,
        'backgroundColor': Colors.blue.withOpacity(0.1),
        'borderColor': Colors.blue.withOpacity(0.3),
        'textColor': Colors.blue,
      };
    }
    if (status.contains('ARRIVED') || status.contains('到達')) {
      return {
        'icon': Icons.flight_land,
        'backgroundColor': Colors.green.withOpacity(0.1),
        'borderColor': Colors.green.withOpacity(0.3),
        'textColor': Colors.green,
      };
    }
    if (status.contains('CANCELLED') || status.contains('取消')) {
      return {
        'icon': Icons.cancel,
        'backgroundColor': Colors.red.withOpacity(0.1),
        'borderColor': Colors.red.withOpacity(0.3),
        'textColor': Colors.red,
      };
    }
    if (status.contains('延誤') || status.contains('Delayed')) {
      return {
        'icon': Icons.access_time,
        'backgroundColor': Colors.orange.withOpacity(0.1),
        'borderColor': Colors.orange.withOpacity(0.3),
        'textColor': Colors.orange,
      };
    }
    return {
      'icon': Icons.airplanemode_active,
      'backgroundColor': Colors.grey.withOpacity(0.1),
      'borderColor': Colors.grey.withOpacity(0.3),
      'textColor': Colors.black87,
    };
  }

  int _calculateDelayMinutes(Map<String, dynamic> flight) {
    try {
      final scheduled = DateTime.parse(widget.type == 'Departure'
          ? flight['ScheduleDepartureTime']
          : flight['ScheduleArrivalTime']);
      final actual = DateTime.parse(widget.type == 'Departure'
          ? flight['ActualDepartureTime']
          : flight['ActualArrivalTime']);
      return actual.difference(scheduled).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    final dt = DateTime.tryParse(isoTime);
    return dt != null ? DateFormat.Hm().format(dt.toLocal()) : '--:--';
  }
}

// ==========================================
// FlightInfoCard
// ==========================================
enum FlightStatus { onTime, delayed, canceled, landed }

class FlightInfoCard extends StatefulWidget {
  final Map<String, dynamic> flight;

  const FlightInfoCard({super.key, required this.flight});

  @override
  State<FlightInfoCard> createState() => _FlightInfoCardState();
}

class _FlightInfoCardState extends State<FlightInfoCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween(begin: 0.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    try {
      final date = DateTime.parse(isoTime).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '--:--';
    }
  }

  Color _getStatusColor() {
    final remark = (isDeparture
        ? widget.flight['DepartureRemark']
        : widget.flight['ArrivalRemark']) ??
        '';

    final l10n = AppLocalizations.of(context)!;
    if (remark.contains(l10n.text_788)) return Colors.orange;
    if (remark.contains(l10n.text_789)) return Colors.green;
    if (remark.contains(l10n.text_36)) return Colors.red;
    return Colors.blue.shade600;
  }

  bool get isArrival =>
      widget.flight['ArrivalRemark'] != null &&
          widget.flight['DepartureRemark'] == null;

  bool get isDeparture =>
      widget.flight['DepartureRemark'] != null &&
          widget.flight['ArrivalRemark'] == null;

  String get airportCode => isDeparture
      ? widget.flight['DepartureAirportID'] ?? '--'
      : widget.flight['ArrivalAirportID'] ?? '--';

  String get terminal => isDeparture
      ? widget.flight['DepartureTerminal'] ?? '--'
      : widget.flight['ArrivalTerminal'] ?? '--';

  String get gate => isDeparture
      ? widget.flight['DepartureGate'] ?? '--'
      : widget.flight['ArrivalGate'] ?? '--';

  Widget _buildAirlineBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          widget.flight['AirlineID'] ?? '--',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeComparison() {
    final scheduledTime = isDeparture
        ? widget.flight['ScheduleDepartureTime']
        : widget.flight['ScheduleArrivalTime'];
    final actualTime = isDeparture
        ? widget.flight['ActualDepartureTime']
        : widget.flight['ActualArrivalTime'];
    final estimatedTime = isDeparture
        ? widget.flight['EstimatedDepartureTime']
        : widget.flight['EstimatedArrivalTime'];
    final remark = isDeparture
        ? widget.flight['DepartureRemark']
        : widget.flight['ArrivalRemark'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '預定時間：${_formatTime(scheduledTime)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        if (actualTime != null)
          Text(
            '實際時間：${_formatTime(actualTime)}',
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          )
        else if (estimatedTime != null)
          const Text(
            '預估時間：',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (remark != null && remark.toString().trim().isNotEmpty)
          Text(
            '備註：$remark',
            style: TextStyle(color: Colors.red.shade600),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _expanded = !_expanded;
            _expanded ? _controller.forward() : _controller.reverse();
          });
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAirlineBadge(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.flight['AirlineID']} ${widget.flight['FlightNumber']}',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                  _getStatusColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isDeparture
                                      ? l10n.text_67
                                      : l10n.text_68,
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$airportCode 第$terminal航廈',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: _buildTimeComparison()),
                    Icon(
                      isDeparture ? Icons.flight_takeoff : Icons.flight_land,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 24),
                            _buildDetailRow(
                              Icons.departure_board,
                              l10n.text_787,
                              gate,
                            ),
                            if (isArrival)
                              _buildDetailRow(
                                Icons.luggage,
                                l10n.text_790,
                                widget.flight['BaggageClaim'] ?? '--',
                              ),
                            _buildDetailRow(
                              Icons.assignment_ind,
                              l10n.text_791,
                              widget.flight['CheckCounter'] ?? '--',
                            ),
                            _buildDetailRow(
                              Icons.update,
                              l10n.text_792,
                              _formatTime(widget.flight['UpdateTime']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _expanded
                      ? Icon(Icons.expand_less,
                      color: Colors.grey.shade500,
                      key: const ValueKey(1))
                      : RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(Icons.expand_more,
                        color: Colors.grey.shade500,
                        key: const ValueKey(2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}