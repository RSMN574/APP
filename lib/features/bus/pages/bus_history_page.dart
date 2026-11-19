import 'package:intl/intl.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_route_stops_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/const/app_colors.dart';

class BusDetailPage extends StatefulWidget {
  final String routeId;
  final String city;

  const BusDetailPage({
    super.key,
    required this.routeId,
    required this.city,
  });

  @override
  State<BusDetailPage> createState() => _BusDetailPageState();
}

class _BusDetailPageState extends State<BusDetailPage> {
  List<Map<String, dynamic>>? allBuses;
  List<Map<String, dynamic>>? filteredBuses;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final List<Map<String, dynamic>> data =
      await context.read<BusProvider>().fetchHistory(
        city: widget.city,
        routeId: widget.routeId,
        count: sum!,
      );
      if (!mounted) return;
      setState(() {
        allBuses = data;
        filteredBuses = List.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        allBuses = [];
        filteredBuses = [];
      });
    }
  }

  void search(String query) {
    if (allBuses == null) return;

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    setState(() {
      filteredBuses = allBuses!
          .where((bus) => BusRouteStopsBuilder.localizedText(
        bus['StopName'],
        isEnglish: isEnglish,
      ).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatTime(String gpsTime) {
    try {
      DateTime dateTime = DateTime.parse(gpsTime).toLocal();
      return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.text_362;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.text_363,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.text_364,
                hintStyle: TextStyle(color: colors.textHint),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.mutedBackground,
              ),
              onChanged: search,
            ),
          ),
          Expanded(
            child: filteredBuses == null
                ? Center(
              child: CircularProgressIndicator(color: colors.info),
            )
                : filteredBuses!.isEmpty
                ? Center(
              child: Text(
                l10n.text_365,
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredBuses!.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.busHistoryPlate}: ${bus['PlateNumb']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '${l10n.busHistoryRoute}: ${BusRouteStopsBuilder.localizedText(
                            bus['RouteName'],
                            isEnglish: isEnglish,
                          )}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${l10n.busHistoryStop}: ${BusRouteStopsBuilder.localizedText(
                            bus['StopName'],
                            isEnglish: isEnglish,
                          )}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${l10n.busHistoryTime}: ${formatTime(bus['GPSTime'])}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${l10n.busHistoryDirection}: ${bus['Direction'] == 0 ? l10n.text_366 : l10n.text_367}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}