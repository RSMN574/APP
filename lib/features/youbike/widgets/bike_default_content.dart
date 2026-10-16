import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/models/bike.dart';
import 'package:flutter/material.dart';

class BikeDefaultContent extends StatefulWidget {
  const BikeDefaultContent({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  final List<YouBikeStation> stations;
  final ValueChanged<YouBikeStation> onStationSelected;

  @override
  State<BikeDefaultContent> createState() => _BikeState();
}

class _BikeState extends State<BikeDefaultContent> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = [];
  static const int _maxHistoryCount = 5;

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<YouBikeStation> fuzzySearchStations(String keyword) {
    if (keyword.isEmpty) return [];
    final keywordLower = keyword.toLowerCase();

    return widget.stations.where((station) {
      final stationName = station.stationName.zhTw.toLowerCase();
      return stationName.contains(keywordLower) ||
          stationName.startsWith(keywordLower) ||
          stationName.endsWith(keywordLower);
    }).toList();
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchHistory.removeWhere((item) => item == query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _maxHistoryCount) {
        _searchHistory.removeLast();
      }
    });
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
  }

  Widget _buildDefaultContent(IconData icon, String text) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 30, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF3FB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.text_142,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          if (_searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _searchHistory
                    .map((query) => _buildHistoryChip(query))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String query) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = query;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(
                query,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ), maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeFromHistory(query),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: const Color(0xFFF8FAFD),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (searchText) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_143,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _clearSearch,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.clear_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildDefaultContent(Icons.location_off_outlined, '請選擇站點')
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final List<YouBikeStation> results =
        fuzzySearchStations(_searchController.text);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '找不到符合「${_searchController.text}」的站點',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final station = results[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _addToSearchHistory(_searchController.text);
              widget.onStationSelected(station);
            },
            splashColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
            highlightColor: const Color(0xFFEEF3FB),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF34C759),
                          Color(0xFF28A745),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.electric_bike_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.stationName.zhTw,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          station.stationAddress.zhTw,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
