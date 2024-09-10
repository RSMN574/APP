import 'package:flutter/material.dart';
import 'package:untitled/widget/tab.dart';

class bus extends StatefulWidget {
  const bus({super.key});

  @override
  State<bus> createState() => _busState();
}

class _busState extends State<bus> {

  TextEditingController BusId = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        //leading: null,
        /**
         * 如果没有leading，automaticallyImplyLeading为true，就会默认返回箭头
         * 如果 没有leading 且为false，空间留给title
         * 如果有leading，这个参数就无效了
         */
          automaticallyImplyLeading : true,
          title: const Text('公車'),

      ),
      body: Container(

        child:Column(children: [
          TextField(
              onChanged:(text){
                print(text);



              },
        controller:BusId,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              )),tab(items: ["路線","地圖","城市","我的最愛"], icons: [Icons.home,Icons.map,Icons.location_city,Icons.favorite], )


        ],) ,

      )

    );

  }

}
