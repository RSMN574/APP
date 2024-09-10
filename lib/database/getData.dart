import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
var result;
String select ="SELECT JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) AS Zh_tw FROM BusInfo WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) LIKE '70%'";
Future<void> getApiBus() async{
  print("Connecting to mysql server...");

  // create connection
  final conn = await MySQLConnection.createConnection(
    host: "rsmn574.serveminecraft.net",
    port: 3306,
    userName: "onlyForApiRead",
    password: "@Nick0319Lucas0221",
    databaseName: "Bus", // optional
  );
try{

  await conn.connect();
} catch(e){
  print(e);
  Fluttertoast.showToast(
      msg: "錯誤",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black45,
      textColor: Colors.white,
      fontSize: 16.0);

}

try{
 result = await conn.execute(select);



}catch(e){
 print(e);
}finally{
  print(result);

  // print query result
  for (final row in result.rows) {
    // print(row.colAt(0));
    // print(row.colByName("title"));

    // print all rows as Map<String, String>
    print(row.assoc());
  }
}

}




