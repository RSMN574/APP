import 'dart:ui';

import 'package:flutter/material.dart';
final   tokenUri=Uri.parse('http://hidden.rsmn574.com:3920/token') ;
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
    fontFamily: 'MiSans-Normal', colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(surface: Colors.white),
    // 应用字体
    scaffoldBackgroundColor:Colors.white
);
