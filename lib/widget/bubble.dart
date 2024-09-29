import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/Const/regularConst.dart';
class bubble extends StatelessWidget {

  final String plateNum;

  bubble({
    required this.plateNum,
  });

  @override
  Widget build(BuildContext context) {
    print(plateNum);
    return Container(

padding: EdgeInsets.all(10),
    decoration: BoxDecoration(

    color: busBlue,

    ),

    child: Text(plateNum,
    style: TextStyle(
    color: Colors.white
    )
    ),



    );
     
  }
}
