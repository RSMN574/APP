import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        height: 200,
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
        child:GridView.count(    //卡片

          primary: false,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 6,
          mainAxisSpacing: 2,
          crossAxisCount: 4,
          children: <Widget>[
    new GestureDetector(
    onTap: (){
    print("Container clicked");

      debugPrint("跳轉頁面");
      Navigator.pushNamed(context, "plane");

    },
    child:Container(
              padding: const EdgeInsets.all(8),

              child: Column(
                  crossAxisAlignment:CrossAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.flight,
                    ),
                    Text("飛機")
                  ]
              ),
           )),
    new GestureDetector(
    onTap: (){
    print("Container clicked");

    debugPrint("跳轉頁面");
    Navigator.pushNamed(context, "train");

    },
    child:  Container(
              padding: const EdgeInsets.all(8),

              child: Column(
                  crossAxisAlignment:CrossAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.train,
                    ),
                    Text("火車"),
                  ]
              )),

            ),
    new GestureDetector(
    onTap: (){
    print("Container clicked");

    debugPrint("跳轉頁面");
    Navigator.pushNamed(context, "bus");
    getApiBus();

    },
    child:Container(
              padding: const EdgeInsets.all(8),

              child: Column(
                  crossAxisAlignment:CrossAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.directions_bus,
                    ),
                    Text("巴士"),
                  ]
              ),
    )),
            Container(
              padding: const EdgeInsets.all(8),

              child: Column(
                  crossAxisAlignment:CrossAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.subway,
                    ),
                    Text("捷運"),
                  ]
              )
            ),
            Container(
                padding: const EdgeInsets.all(10),

                child:Column(
                    crossAxisAlignment:CrossAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.directions_railway,
                      ),
                      Text("高鐵"),
                    ]
                ) ,),

            Container(
                padding: const EdgeInsets.all(8),

                child: Column(
                    crossAxisAlignment:CrossAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.directions_bike,
                      ),
                      Text("Ubike"),
                    ]
                )
            ),Container(
                padding: const EdgeInsets.all(8),

                child: Column(
                    crossAxisAlignment:CrossAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.subway,
                      ),
                      Text("捷運"),
                    ]
                )
            ),Container(
                padding: const EdgeInsets.all(8),

                child: Column(
                    crossAxisAlignment:CrossAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.subway,
                      ),
                      Text("捷運"),
                    ]
                )
            ),
          ],
        )
        ,
      )











    ],
  ),
);







  }
}
