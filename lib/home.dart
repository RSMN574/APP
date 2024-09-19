
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
      TransportGrid()












    ],
  ),
);







  }
}
