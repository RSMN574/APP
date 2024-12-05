import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';
import '../database/getBusTime.dart';
import '../models/Station.dart';

class NearbyStationsPage extends StatelessWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '附近公車站牌',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600, // 调整字体为中等粗细
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Station>>(
        future: getNearStation(
          "${locationProvider.latitude}%2C${locationProvider.longitude}",
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "找不到附近的站牌",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          } else {
            final stations = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
                  return StationCard(station: station);
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({required this.station, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.stationNameZh,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500, // 调整为中等粗细
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 8),
          Column(
            children: station.stops.map((stop) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stop.routeNameZh,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400, // 普通粗细
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      stop.stopNameZh,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300, // 更轻的字体
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
