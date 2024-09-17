
import 'package:flutter/material.dart';
import 'package:untitled/widget/transportGrid.dart';

import 'database/getData.dart';

class home extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return

Container(
  width: MediaQuery.of(context).size.width,
  color: const Color(0xFFECEFFE),
  child: Column(


    children: [
      TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          )),
      Container(
        height: 220,
margin: EdgeInsets.only(top:20),
    decoration: BoxDecoration(

        borderRadius:BorderRadius.all(Radius.circular(30)),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x35000000),
          blurRadius: 1,
          offset: Offset(1, 2),
          spreadRadius: 0,
        )
      ],
    ),
        child:TransportGrid()

      )











    ],
  ),
);







  }
}
