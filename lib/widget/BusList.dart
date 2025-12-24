import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/Const/regularConst.dart';

import '../database/getData.dart';
import '../database/shared_perferences.dart';
import '../pages/bus_time.dart';

class Buslist extends StatefulWidget {
  final List suggestions;
  final String city;

  const Buslist({required this.suggestions, required this.city});

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  List<String> favoritesBusRoute = [];

  // 航班主題顏色
  final Color _primaryColor = const Color(0xFF1A73E8);
  final Color _secondaryColor = const Color(0xFFEEF3FB);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _greyColor = Colors.grey;

  @override
  void initState() {
    super.initState();
  }

  String extractZhTw(jsonString) {
    return json.decode(jsonString)["Zh_tw"];
  }

  @override
  Widget build(BuildContext context) {
    return widget.suggestions.isEmpty
        ? _buildEmptyState()
        : ListView.separated(
      itemCount: widget.suggestions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final route = widget.suggestions[index];
        return _buildRouteCard(route, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '找不到此公車路線',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '請嘗試其他搜尋關鍵字',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(dynamic route, int index) {
    final isFirstItem = index == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isFirstItem ? 0.08 : 0.05),
            blurRadius: isFirstItem ? 12 : 8,
            offset: Offset(0, isFirstItem ? 4 : 2),
          ),
        ],
        border: isFirstItem
            ? Border.all(color: _primaryColor.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToRouteDetails(route),
          splashColor: _primaryColor.withOpacity(0.1),
          highlightColor: _secondaryColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左側圖標區域
                _buildRouteIcon(),
                const SizedBox(width: 16),

                // 中間資訊區域
                Expanded(
                  child: _buildRouteInfo(route),
                ),

                // 右側箭頭
                _buildNavigationArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteIcon() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        'assets/icons/bus-outline.svg',
        color: _primaryColor,
      ),
    );
  }

  Widget _buildRouteInfo(dynamic route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 路線名稱
        Text(
          extractZhTw(route["RouteName"]),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // 起點終點資訊
        _buildRouteDetails(route),
      ],
    );
  }

  Widget _buildRouteDetails(dynamic route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          icon: Icons.place_outlined,
          text: '起點: ${route["DepartureStopNameZh"]}',
        ),
        const SizedBox(height: 2),
        _buildDetailRow(
          icon: Icons.flag_outlined,
          text: '終點: ${route["DestinationStopNameZh"]}',
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationArrow() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _secondaryColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Color(0xFF1A73E8),
      ),
    );
  }

  Future<void> _navigateToRouteDetails(dynamic route) async {
    await GetBusInfo(
        routeid: int.parse(route["RouteID"]),
      city: route['City'] ?? 'InterCity',

    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BusTime(
          routeName: extractZhTw(route["RouteName"]),
          departureStopName: route["DepartureStopNameZh"],
          destinationStopName: route["DestinationStopNameZh"],
          operators: route["Operators"],
          routeMapImageUrl: route["RouteMapImageUrl"],
          city: route['City'] ?? 'InterCity',
          routeID: int.parse(route["RouteID"]),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  // 可選：添加收藏功能
  Widget _buildFavoriteButton(dynamic route) {
    final isFavorite = favoritesBusRoute.contains(route["RouteID"]);

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey[400],
        size: 20,
      ),
      onPressed: () {
        setState(() {
          if (isFavorite) {
            favoritesBusRoute.remove(route["RouteID"]);
          } else {
            favoritesBusRoute.add(route["RouteID"]);
          }
        });
        // 保存到本地儲存
        // saveList("favoritesBusRoute", favoritesBusRoute);
      },
    );
  }
}