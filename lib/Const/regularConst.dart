
import 'package:flutter/material.dart';
final   tokenUri=Uri.parse('http://hidden.rsmn574.com:3920/token') ;
final   tokens=Uri.parse('http://hidden.rsmn574.com:3920/tokens') ;
const Color primary=Color.fromRGBO(0,125,254, 1);
const Color secondary=Color.fromRGBO(38,38,38, 1);
const Color blue=Color.fromRGBO(36,137,243, 1);
 const Color busBlue=Color.fromRGBO(2,101,143, 1);
final Color startColor = Color.fromARGB(255, 13, 193, 255); // (13,193,255)
final Color endColor = Color.fromARGB(255, 27, 141, 255);   // (27,141,255)
final Color bgColor =Color.fromRGBO(245,245,245,1);
final Color bgColorWhite =Colors.white;
final ThemeData appTheme = ThemeData(
 useMaterial3: true,
 colorScheme: ColorScheme.fromSwatch(
  primarySwatch: Colors.blue,
 ).copyWith(
  surface: Colors.white, // 背景颜色
  onSurface: Colors.black, // 文字颜色3
 ),
 scaffoldBackgroundColor: Colors.white,

 // AppBar 样式
 appBarTheme: const AppBarTheme(
  backgroundColor: Colors.white,
  elevation: 0,
  titleTextStyle: TextStyle(
   fontSize: 20,
   fontWeight: FontWeight.bold,
   color: Colors.black,
  ),
  iconTheme: IconThemeData(color: Colors.black),
 ),

 // 按钮样式
 elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
   foregroundColor: Colors.white,
   backgroundColor: Colors.blue,
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   elevation: 2,
   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  ),
 ),

 // 输入框样式
 inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: Colors.grey[100], // 背景颜色
  border: OutlineInputBorder(
   borderRadius: BorderRadius.circular(10),
   borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 ),

 // 文本样式
 textTheme: const TextTheme(
  bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
  bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
 ),

 // Card 样式
 cardTheme: CardThemeData(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  color: Colors.white,
 ),
);
