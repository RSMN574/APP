import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/WeatherCard.dart';
import 'package:com.rsmn574.app/widget/transportGrid.dart';
import 'Const/regularClass.dart';
import 'database/getData.dart'; // 你可能需要根据具体情况更改路径


class home extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: const Color.fromRGBO(245, 245, 245, 1),
      child:
             Column(
              children: [
                WeatherWidget( ),
                const TransportGrid(),
              ],

                ) );
  }
}
