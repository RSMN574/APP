import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RoutePlanner extends StatefulWidget {
  @override
  _RoutePlannerState createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  // 交通工具選擇
  List<String> transportModes = [
    '火車',
    '高鐵',
    '捷運',
    '公車',
    '飛機',
    '客運',
    'Ubike',
  ];
  String selectedTransport = '公車';

  // 出發點和目的地
  TextEditingController departureController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  // 時間選擇
  TimeOfDay selectedTime = TimeOfDay.now(); // 確保這裡已聲明
  // 假設的站牌列表
  List<String> busStops = [
    '中華路北站',
    '台北車站',
    '信義安和站',
    '市政府站',
    '公館站',
    '劍潭站',
  ];

  // 搜索結果
  List<String> filteredStops = [];

  @override
  void initState() {
    super.initState();
    filteredStops = busStops; // 初始化時顯示所有站牌
  }

  // 顯示選擇站牌的彈窗
  void showBusStopPicker(TextEditingController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('選擇站牌'),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '搜尋站牌',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filteredStops = busStops
                            .where((stop) => stop.contains(searchQuery))
                            .toList();
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // 限制彈窗高度
                child: ListView.builder(
                  itemCount: filteredStops.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredStops[index]),
                      onTap: () {
                        controller.text = filteredStops[index];
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('關閉'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // 交通工具選擇
          DropdownButton<String>(
            value: selectedTransport,
            onChanged: (String? newValue) {
              setState(() {
                selectedTransport = newValue!;
              });
            },
            items: transportModes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 出發點
          GestureDetector(
            onTap: selectedTransport == '公車'
                ? () => showBusStopPicker(departureController)
                : null,
            child: AbsorbPointer(
              absorbing: selectedTransport == '公車',
              child: TextField(
                controller: departureController,
                decoration: InputDecoration(
                  labelText: '出發點',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 目的地
          GestureDetector(
            onTap: selectedTransport == '公車'
                ? () => showBusStopPicker(destinationController)
                : null,
            child: AbsorbPointer(
              absorbing: selectedTransport == '公車',
              child: TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: '目的地',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 時間選擇
          Row(
            children: [
              const Text('出發時間:'),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null && picked != selectedTime) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
                child: Text(
                  '${selectedTime.format(context)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // 計劃路線按鈕
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('路線計劃'),
                    content: Text(
                      '交通工具: $selectedTransport\n'
                          '出發點: ${departureController.text}\n'
                          '目的地: ${destinationController.text}\n'
                          '時間: ${selectedTime.format(context)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('關閉'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('計劃路線'),
          ),
        ],
      ),
    );
  }
}
