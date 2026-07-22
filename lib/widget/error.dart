import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF86537),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插圖部分，替換為你自己的圖片
            // Image.network(
            //   'https://your-image-url.com/image.png',
            //   width: 150,
            //   height: 150,
            //   fit: BoxFit.cover,
            // ),
            const SizedBox(height: 30),
            // 顯示 404 錯誤代碼
            Text(
              '404',
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // 顯示 "Oh No!" 標題
            Text(
              'Oh No!',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            // 顯示 "Something went wrong" 說明
            Text(
              'Something went wrong!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            // 返回首頁按鈕
            ElevatedButton(
              onPressed: () {
                // 返回首頁的功能
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.black, // 按鈕顏色
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 圓角按鈕
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.text_915,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}