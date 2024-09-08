import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
Future<void> getApiBus() async{
  print("Connecting to mysql server...");

  // create connection
  final conn = await MySQLConnection.createConnection(
    host: "rsmn574.serveminecraft.net",
    port: 3306,
    userName: "RSMN",
    password: "Nick0319",
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

}finally{
Fluttertoast.showToast(
msg: "連線成功",
toastLength: Toast.LENGTH_SHORT,
gravity: ToastGravity.BOTTOM,
timeInSecForIosWeb: 1,
backgroundColor: Colors.black45,
textColor: Colors.white,
fontSize: 16.0);
}
print("連線成功");
}




