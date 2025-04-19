import 'package:flutter/material.dart';

class IntercityBus extends StatefulWidget {
  @override
  _IntercityBusState createState() => _IntercityBusState();
}

class _IntercityBusState extends State<IntercityBus> {
  // 用於儲存用戶選擇的站點、日期和時間
  String? _departureStation;
  String? _arrivalStation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  // 模擬站點列表
  final List<String> stations = ['台北', '台中', '高雄', '台南'];

  // 模擬搜尋結果
  void _performSearch() {
    setState(() {
      _searchResults = [
        '班次 1: $_departureStation -> $_arrivalStation (${_selectedDate?.toString().split(' ')[0]}, ${_selectedTime?.format(context)})',
        '班次 2: $_departureStation -> $_arrivalStation (${_selectedDate?.toString().split(' ')[0]}, ${_selectedTime?.format(context)})',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 只保留標題
      appBar: AppBar(
        title: const Text('城際客運搜尋'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 搜尋框移到畫面上方，並用 Container 美化背景及圓角
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜尋站點或班次',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // 這裡可以實現具體搜尋邏輯
                      print('搜尋: ${_searchController.text}');
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 搜尋條件卡片
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 站點選擇：包含出發站和到達站
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _departureStation,
                            hint: const Text('出發站'),
                            isExpanded: true,
                            items: stations.map((String station) {
                              return DropdownMenuItem<String>(
                                value: station,
                                child: Text(station),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _departureStation = newValue;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () {
                            setState(() {
                              final temp = _departureStation;
                              _departureStation = _arrivalStation;
                              _arrivalStation = temp;
                            });
                          },
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _arrivalStation,
                            hint: const Text('到達站'),
                            isExpanded: true,
                            items: stations.map((String station) {
                              return DropdownMenuItem<String>(
                                value: station,
                                child: Text(station),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _arrivalStation = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 日期選擇
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('選擇日期'),
                      subtitle: Text(_selectedDate == null
                          ? '請選擇日期'
                          : _selectedDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),

                    // 時間選擇
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('選擇時間'),
                      subtitle: Text(_selectedTime == null
                          ? '請選擇時間'
                          : _selectedTime!.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 搜尋按鈕
            ElevatedButton(
              onPressed: (_departureStation != null &&
                  _arrivalStation != null &&
                  _selectedDate != null &&
                  _selectedTime != null)
                  ? _performSearch
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('搜尋班次', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // 搜尋結果
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(child: Text('請輸入條件後搜尋'))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(_searchResults[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
