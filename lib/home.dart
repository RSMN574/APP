
import 'package:flutter/material.dart';
import 'package:untitled/widget/transportGrid.dart';

import 'database/getData.dart';

class home extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return

Container(
  width: MediaQuery.of(context).size.width,
  color: const Color.fromRGBO(245,245,245,1),
  child: Column(


    children: [

      TransportGrid(),












    ],
  ),
);







  }
}
