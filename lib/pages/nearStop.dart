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

    return
     FutureBuilder<List<Station>>(
        future: getNearStation(
          "${locationProvider.latitude}%2C${locationProvider.longitude}",
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }else if (snapshot.hasError) {
            return const Center(
              child: Text("找不到附近的站牌"), // 显示错误信息
            );
          }else{
            final stations = snapshot.data!;
            return ListView.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return StationCard(station: station);
              },
            );
          }


        },
      );

  }
}

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({required this.station, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.stationNameZh,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...station.stops.map((stop) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stop.routeNameZh),
                    Text(stop.stopNameZh, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
