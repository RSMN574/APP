import 'package:flutter/material.dart';

PopupMenuItem<String> SelectView({
  required IconData icon,
  required String text,
  required String id,
  Color iconColor = Colors.black,
}) {
  return PopupMenuItem<String>(
    value: id,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Icon(icon, color: iconColor),
        Text(text),
      ],
    ),
  );
}
