import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import 'firebase/FCM.dart';

class pages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(

      children: [
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
                Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconText(Icons.schedule, '歷史行程'),
                _buildIconText(Icons.apartment, '城市'),
                _buildIconText(Icons.public, '里程'),
              ],
            ),
          ],
        ),
      ),
    ),
        SizedBox(height: 20,),Container(//按鈕

          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ Color.fromARGB(255, 13, 193, 255), Color.fromARGB(255, 27, 141, 255)], // 使用顏色變數
              begin: Alignment.centerLeft,     // 從左邊開始
              end: Alignment.centerRight,      // 到右邊結束
            ),
            borderRadius: BorderRadius.circular(16), // 圓角邊框
          ),
          child: TextButton(
            onPressed: () async {
              // 按鈕被按下的行為

              QuickAlert.show(
                context: context,
                type: QuickAlertType.info,
                text: "版本號:0.1.7 封測版 \n"
                    "token:$FCMtoken",
              );
            },
            child: Text(
              '封測版',
              style: TextStyle(
                color: Colors.white, // 字體顏色
                fontSize:17,        // 字體大小
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // 按鈕的內邊距
              backgroundColor: Colors.transparent, // 背景顏色透明，讓漸層顯示
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
