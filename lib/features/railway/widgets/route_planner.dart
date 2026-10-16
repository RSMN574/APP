// 彈窗內容

import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

class StationSelectionDialog extends StatefulWidget {
  final List<dynamic> stationNames;
  const StationSelectionDialog({Key? key, required this.stationNames})
      : super(key: key);
  @override
  State<StationSelectionDialog> createState() => _StationSelectionDialogState();
}

class _StationSelectionDialogState extends State<StationSelectionDialog> {
  // 表單控制器
  final _formKey = GlobalKey<FormState>();
  String? _departure;
  String? _destination;
  String? _category;
  String? _seatNumber;
  // 車站選項
  late List<String> stations = [
    AppLocalizations.of(context)!.text_85,
    AppLocalizations.of(context)!.text_88,
    AppLocalizations.of(context)!.text_90,
    AppLocalizations.of(context)!.text_89,
    AppLocalizations.of(context)!.text_924
  ];
  late final List<String> category = [
    AppLocalizations.of(context)!.text_70,
    AppLocalizations.of(context)!.text_71,
  ];

  @override
  Widget build(BuildContext context) {
    print(widget.stationNames);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    List<String> stationNames = widget.stationNames.map((stop) {
      final preferred = stop[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
      if (preferred.isNotEmpty) return preferred;
      return stop[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
    }).toList();
    stations = stationNames;
    print(stationNames);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.text_925),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 出發站選擇
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.text_63),
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
                    return AppLocalizations.of(context)!.text_161;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 到達站選擇
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.text_162),
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
                    return AppLocalizations.of(context)!.text_163;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 類型選擇
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.text_926),
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
                    return AppLocalizations.of(context)!.text_927;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 座位號碼輸入框
              TextFormField(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.text_928),
                maxLength: 10, // 限制最多 10 個字
                onChanged: (value) {
                  setState(() {
                    _seatNumber = value;
                  });
                },
                validator: (value) {
                  if (value!.length > 10) {
                    return AppLocalizations.of(context)!.text_929;
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
          child: Text(AppLocalizations.of(context)!.text_36),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // 返回用戶選擇的結果
              Navigator.pop(context, {
                'departure': _departure,
                'destination': _destination,
                'category': _category,
                'seatNumber': _seatNumber, // 加入座位號碼
              });
            }
          },
          child: Text(AppLocalizations.of(context)!.text_35),
        ),
      ],
    );
  }
}
