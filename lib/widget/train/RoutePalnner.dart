// 彈窗內容

import 'package:flutter/material.dart';

class StationSelectionDialog extends StatefulWidget {
  final List<dynamic> stationNames;
  const StationSelectionDialog({
  Key? key,required this.stationNames
  }) : super(key: key);
   @override
  State<StationSelectionDialog> createState() => _StationSelectionDialogState();
}

class _StationSelectionDialogState extends State<StationSelectionDialog> {

  // 表單控制器
  final _formKey = GlobalKey<FormState>();
  String? _departure;
  String? _destination;
  String? _category;

  // 車站選項
  List<String> stations = ['台北', '台中', '高雄', '台南', '新竹'];
  final List<String> category = ['上班通勤', '旅行', ];

  @override
  Widget build(BuildContext context) {
    print(widget.stationNames);
    List<String> stationNames = widget.stationNames
        .map((stop) => stop["Zh_tw"] as String)
        .toList();
    stations=stationNames;
    print(stationNames);
    return AlertDialog(
      title: const Text('選擇車站'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 出發站選擇
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '出發站'),
                value: _departure,
                items: stations.map((station) {
                  return DropdownMenuItem(
                    value: station,
                    child: Text(station),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _departure = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '請選擇出發站';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 到達站選擇
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '到達站'),
                value: _destination,
                items: stations.map((station) {
                  return DropdownMenuItem(
                    value: station,
                    child: Text(station),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _destination = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '請選擇到達站';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 類型選擇
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '類型'),
                value: _category,
                items: category.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '請選擇類型';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // 關閉彈窗
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // 返回用戶選擇的結果
              Navigator.pop(context, {
                'departure': _departure,
                'destination': _destination,
                'category': _category,
              });
            }
          },
          child: const Text('確認'),
        ),
      ],
    );
  }
}