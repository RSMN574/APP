import 'package:flutter/material.dart';
import 'package:untitled/widget/BusList.dart';
import 'package:untitled/widget/tab.dart';
import 'database/getData.dart';
double suggestionsIsHidden=0;
 List suggestions = [];
class Bus extends StatefulWidget {

  const Bus({Key? key}) : super(key: key);
  @override
  State<Bus> createState() => BusState();
}

class BusState extends State<Bus> {
  double suggestionsIsHidden=0;
  TextEditingController busIdController = TextEditingController();

  suggestionsIsHiddenController(){

   for(int i=0;i<busName.length;i++){

     if(busName[i]["RouteName"].contains(busIdController.text)){
print("找到"+busName[i]["RouteName"]+busName[i]["DepartureStopNameZh"]+"-"+busName[i]["DestinationStopNameZh"]);
suggestions.add(busName[i]);

     }
   }
print(suggestions);

    // if(busName !=[]){
    //   if(busName[0]["RouteName"]["Zh_tw"]==int.parse(busIdController.text)){
    //        suggestionsIsHidden=200;
    //      }
    //
    // }


    setState(() {
      suggestionsIsHidden=200.0;
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('公車'),
      ),

      body: Container(
        height: 800,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextField(
              onChanged: (text) async {
                if (text.isNotEmpty) {
                  //await GetApi();
                  suggestions.clear();
                  suggestionsIsHiddenController();
                }else{
                  setState(() {
                    suggestionsIsHidden=0;
                  });

                }
              },
              controller: busIdController,
              decoration: InputDecoration(
                hintText: 'Search for a bus route...',
                hintStyle: TextStyle(
                  color: Colors.grey[500], // 提示文本顏色
                  fontSize: 16, // 提示文本大小
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[700], // 搜索圖標顏色
                  size: 24, // 圖標大小
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), // 圓角邊框
                  borderSide: BorderSide.none, // 無邊框
                ),
                filled: true,
                fillColor: Colors.grey[200], // 背景顏色
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), // 聚焦時的圓角
                  borderSide: BorderSide(
                    color: Colors.blueAccent, // 聚焦時的邊框顏色
                    width: 2.0, // 邊框寬度
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), // 正常狀態的圓角
                  borderSide: BorderSide(
                    color: Colors.grey[300]!, // 默認的邊框顏色
                    width: 2.0,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  color: Colors.grey[700], // 清除按鈕的顏色
                  onPressed: () {
                    busIdController.clear(); // 清空文本框
                  },
                ),
              ),
              style: TextStyle(
                color: Colors.black87, // 輸入文本的顏色
                fontSize: 16, // 字體大小
              ),
            ),
            const SizedBox(height: 16.0),
            Stack(children: [
              tab(
                items: ["路線", "地圖", "城市", "我的最愛"],
                icons: [Icons.home, Icons.map, Icons.location_city, Icons.favorite],
              ),
              Container(
                color: Colors.red,
                height: suggestionsIsHidden,

              )
            ],),

          ],
        ),
      ),
    );
  }
}
