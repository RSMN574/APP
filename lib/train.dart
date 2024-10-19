import 'package:flutter/material.dart';

class Train extends StatefulWidget {
  @override
  _TrainState createState() => _TrainState();
}

class _TrainState extends State<Train> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('火車查詢系統'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '按車次查詢'),
            Tab(text: '按出發地和目的地查詢'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TripNumberSearchPage(),
          RouteSearchPage(),
        ],
      ),
    );
  }
}

class TripNumberSearchPage extends StatefulWidget {
  @override
  _TripNumberSearchPageState createState() => _TripNumberSearchPageState();
}

class _TripNumberSearchPageState extends State<TripNumberSearchPage> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '輸入車次',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? '選擇日期'
                    : '選擇日期: ${selectedDate!.toLocal()}'.split(' ')[0],
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 進行查詢的邏輯
              },
              child: Text('查詢'),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteSearchPage extends StatefulWidget {
  @override
  _RouteSearchPageState createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '出發地',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '目的地',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? '選擇日期'
                    : '選擇日期: ${selectedDate!.toLocal()}'.split(' ')[0],
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 進行查詢的邏輯
              },
              child: Text('查詢'),
            ),
          ],
        ),
      ),
    );
  }
}
