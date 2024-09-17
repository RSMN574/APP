import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled/bus.dart';
final GlobalKey<BusState> _key = GlobalKey<BusState>();
var result;
MySQLConnection? conn;
var busid;
List busName=[];

Future<void> connMysql() async {
  print("Connecting to MySQL server...");

  // 如果連接已存在，則避免重複連接
  if (conn != null) {
    print("Already connected to the database.");
    return;
  }

  try {
    // 建立連接
    conn = await MySQLConnection.createConnection(
      host: "hidden.rsmn574.com",
      port: 3306,
      userName: "onlyForApiRead",
      password: "@Nick0319Lucas0221",
      databaseName: "Bus",
    ) ;
    await conn!.connect();
    print("MySQL connection established.");
  } catch (e) {
    print("Connection error: $e");
    Fluttertoast.showToast(
      msg: "連接失敗: $e",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black45,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

Future<void> GetApi() async {
  if (conn == null) {
    await connMysql(); // 如果未連接，先連接資料庫
  }
  var queryResults;
  // 使用參數化查詢以避免 SQL 注入
  String query =
      "SELECT * FROM NewBusInfo WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) LIKE '%'";
  String query2 =
      "SELECT * FROM NewBusInfo ";
  busName=[];
  try {
    busName.clear();
    result =await conn?.execute(query2);
    // List<Map<String, dynamic>> queryResults = [];

    // 迭代結果並將其儲存到 list 中
    for (final row in result.rows) {
       //print(row.colAt(0));
       //print(row.colByName("Zh_tw"));

      // print all rows as Map<String, String>
       busName.add(row.assoc());



    }
print(busName);
    // 打印結果，方便調試


    // if (queryResults.isEmpty) {
    //   Fluttertoast.showToast(
    //     msg: "無匹配的公車路線",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.BOTTOM,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.black45,
    //     textColor: Colors.white,
    //     fontSize: 16.0,
    //   );
    // }
  } catch (e) {
    print("Query error: $e");
    Fluttertoast.showToast(
      msg: "查詢失敗: $e",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black45,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } finally {
    print("Query completed.");
  }
  return;
}
GetBusInfo(int routeid) async {
  if (conn == null) {
    await connMysql(); // 如果未連接，先連接資料庫
  }
  var query ='SELECT Stops FROM Bus.Bus_Taichung where Routeid=$routeid';
int? sum=0;
  List jsonData=await mysqlSelect(query);
  for(var i in jsonData){
    sum=(sum!+json.decode(i['Stops']).length) as int?;
    // print(json.decode(i['Stops']).length);
  }

    print(sum);


}
Future mysqlSelect (String v)async{
  if (conn == null) {
    await connMysql(); // 如果未連接，先連接資料庫
  }
  List<dynamic> jsonArray=[];
  jsonArray.clear();
  result =await conn?.execute(v);
  for (final row in result.rows) {

    //print(row.colByName("Zh_tw"));

    // print all rows as Map<String, String>

    jsonArray.add(row.assoc());



  }
return jsonArray;


}