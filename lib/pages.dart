import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import 'firebase/FCM.dart';
import 'pages/city.dart';
import 'pages/other/settings.dart'; // 設定頁面

class InfoPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 用戶資料容器
        Container(
          alignment: Alignment.topCenter,
          child: Container(
            width: 327,
            height: 138,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF475363),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage("https://via.placeholder.com/58x73"),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nick',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '測試BETA人員',
                          style: TextStyle(
                            color: Color(0xFFCAE0FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    // 設定按鈕
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsPage()), // 跳轉到設定頁
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconText(context, Icons.schedule, '歷史行程', "history"),
                    _buildIconText(context, Icons.apartment, '城市', "city"),
                    _buildIconText(context, Icons.public, '里程', "mile"),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 封測版按鈕
        Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 13, 193, 255),
                Color.fromARGB(255, 27, 141, 255)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextButton(
            onPressed: () async {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.info,
                text: "版本號: 0.1.9 封測版 \n"
                    "token: $FCMtoken",
                confirmBtnText: "複製 token",
                onConfirmBtnTap: () {
                  Clipboard.setData(ClipboardData(text: FCMtoken ?? "無效的 token"))
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Token 複製到剪貼簿')),
                    );
                  });
                  Navigator.of(context).pop();
                },
              );
            },
            child: Text(
              '封測版',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconText(context, IconData icon, String text, String id) {
    return GestureDetector(
      onTap: () {
        if (id == 'city') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => City()),
          );
        }
      },
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
