import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/shared_perferences.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';

class Buslist extends StatefulWidget {
  final List suggestions;
  final String city;

  const Buslist({required this.suggestions, required this.city});

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> with AutomaticKeepAliveClientMixin {
  List<String> favoritesBusRoute = [];


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
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
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.text_913,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.text_914,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(dynamic route, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFirstItem = index == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(
              isFirstItem ? 0.10 : 0.05,
            ),
            blurRadius: isFirstItem ? 12 : 8,
            offset: Offset(0, isFirstItem ? 4 : 2),
          ),
        ],
        border: isFirstItem
            ? Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToRouteDetails(route),
          splashColor: colorScheme.primary.withOpacity(0.12),
          highlightColor: colorScheme.primary.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildRouteIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRouteInfo(route),
                ),
                _buildNavigationArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteIcon() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        'assets/icons/bus-outline.svg',
        colorFilter: ColorFilter.mode(
          colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildRouteInfo(dynamic route) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final routeName =
        isEnglish && route.routeEn.isNotEmpty ? route.routeEn : route.routeZh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 路線名稱
        Text(
          routeName,
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
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final departureName = isEnglish && route.departureStopNameEn.isNotEmpty
        ? route.departureStopNameEn
        : route.departureStopNameZh;
    final destinationName = isEnglish && route.destinationStopNameEn.isNotEmpty
        ? route.destinationStopNameEn
        : route.destinationStopNameZh;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          icon: Icons.place_outlined,
          text: '${localizations.text_55}: $departureName',
        ),
        const SizedBox(height: 2),
        _buildDetailRow(
          icon: Icons.flag_outlined,
          text: '${localizations.text_57}: $destinationName',
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: colorScheme.primary,
      ),
    );
  }

  Future<void> _navigateToRouteDetails(dynamic route) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final departureStopName = isEnglish && route.departureStopNameEn.isNotEmpty
        ? route.departureStopNameEn
        : route.departureStopNameZh;
    final destinationStopName =
        isEnglish && route.destinationStopNameEn.isNotEmpty
            ? route.destinationStopNameEn
            : route.destinationStopNameZh;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BusTime(
            routeName: route.routeZh,
            departureStopName: departureStopName,
            destinationStopName: destinationStopName,
            operators: route.operatorName,
            routeMapImageUrl: route.routeMapUrl,
            city: route.routeCity ?? 'InterCity',
            routeID: route.routeId,
            hasSubRoutes: route.hasSubRoute,
            data: route),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
    final isFavorite = favoritesBusRoute.contains(route.routeId);

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey[400],
        size: 20,
      ),
      onPressed: () {
        setState(() {
          if (isFavorite) {
            favoritesBusRoute.remove(route.routeId);
          } else {
            favoritesBusRoute.add(route.routeId);
          }
        });
        // 保存到本地儲存
        // saveList("favoritesBusRoute", favoritesBusRoute);
      },
    );
  }

  @override
  bool get wantKeepAlive => true; // 保持頁面狀態3
}
