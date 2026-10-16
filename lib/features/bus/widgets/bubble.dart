import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';

class bubble extends StatelessWidget {
  final String plateNum;

  bubble({
    required this.plateNum,
  });

  @override
  Widget build(BuildContext context) {
    if (plateNum != "") {
      return Container(
        padding: EdgeInsets.all(6.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromRGBO(84, 87, 165, 0.9),
        ),
        child: Text(plateNum,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      );
    } else {
      return const SizedBox();
    }
  }
}
