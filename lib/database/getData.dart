import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:com.rsmn574.app/bus.dart';
final GlobalKey<BusState> _key = GlobalKey<BusState>();
Timer? _idleTimer;
const int idleTimeout = 30; // 30秒無操作超時
var result;
MySQLConnection? conn;
var busid;
List busName=[];
int? sum=0;
List jsonData=[];
int routeID=0;
String busCurrentCity='Taichung';
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
    // 启动閒置計時器
    _startIdleTimer();
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

Future<List> GetBus(String city ) async {

    await connMysql(); // 連接資料庫
// String query='''
// SELECT *
// FROM Bus.Bus_${city}_Route
// WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) LIKE '%${RouteName}%'
// ''';

  // 使用參數化查詢以避免 SQL 注入
  String query2 =
      "SELECT * FROM Bus.Bus_${city}_Route";
  if(city=="all"){
     query2 =
        """
        SELECT UID, RouteUID, RouteID, HasSubRoutes, Operators, AuthorityID, ProviderID, SubRoutes, BusRouteType, RouteName, DepartureStopNameZh, DepartureStopNameEn, DestinationStopNameZh, DestinationStopNameEn, RouteMapImageUrl, City, CityCode, UpdateTime, VersionID
FROM Bus.Bus_Taipei_Route
UNION ALL
SELECT UID, RouteUID, RouteID, HasSubRoutes, Operators, AuthorityID, ProviderID, SubRoutes, BusRouteType, RouteName, DepartureStopNameZh, DepartureStopNameEn, DestinationStopNameZh, DestinationStopNameEn, RouteMapImageUrl, City, CityCode, UpdateTime, VersionID
FROM Bus.Bus_Taichung_Route;
 """;
  }
  List data=[];

  try {
    data.clear();
    result =await conn?.execute(query2);
    // List<Map<String, dynamic>> queryResults = [];

    // 迭代結果並將其儲存到 list 中
    for (final row in result.rows) {
       //print(row.colAt(0));
       //print(row.colByName("Zh_tw"));

      // print all rows as Map<String, String>
      data.add(row.assoc());



    }

    // 打印結果，方便調試

// print( busName);

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
    // print("Query completed. ${data}");
    // 重置閒置計時器
    _startIdleTimer();
    return data;

  }

}
GetBusInfo(int routeid,String city) async {
  routeID=routeid;
  sum=0;
  List routeName=[];

  await connMysql(); // 連接資料庫

  var query ='SELECT Stops FROM Bus.Bus_$city where Routeid=$routeid';

 jsonData=await mysqlSelect(query);
  for(var i in jsonData){
    sum=(sum!+json.decode(i['Stops']).length) as int?;
    routeName.add(i);
    // print(json.decode(i['Stops']).length);
  }


  // 重置閒置計時器
  _startIdleTimer();

return routeName;

}
Future mysqlSelect (String v)async{


  await connMysql(); // 連接資料庫

  List<dynamic> jsonArray=[];
  jsonArray.clear();
 try{
   result =await conn?.execute(v);
 }catch(e){
   await connMysql(); // 如果未連接，先連接資料庫
   if(e.toString().contains("connection closed")){
     await connMysql();
   }else{
     print(e);
   }
 }finally{
   // 重置閒置計時器
   _startIdleTimer();
 }
  for (final row in result.rows) {

    //print(row.colByName("Zh_tw"));

    // print all rows as Map<String, String>

    jsonArray.add(row.assoc());



  }
  // print(jsonArray);
return jsonArray;


}
getInfo(data){
 if(data=='sum'){
   return sum;
 }else if(data=='routeInfo'){
   return jsonData;
 }else if(data=='routeID'){
   return routeID;
 }
}

GetBusStopInfo(String stopName ,String city,) async {

  await connMysql(); // 連接資料庫


  var query =  "SELECT  StationID,StationPosition FROM Bus.Bus_${city}_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '$stopName'";
  List stopInfo=[];

  jsonData=await mysqlSelect(query);
  for(var i in jsonData){
    stopInfo.add(i);
  }

  // 重置閒置計時器
  _startIdleTimer();


  return stopInfo ;
}


Future<dynamic> fetchByUrl(String url, {dynamic other}) async {

  final tokenUri = Uri.parse('http://hidden.rsmn574.com:3920/token');
  // var url="https://tdx.transportdata.tw/api/basic/v2/Bus/Alert/City/Taichung?%24top=10&%24format=JSON";
  try {
    await connMysql(); // 連接資料庫
    final tokenResponse = await http.get(tokenUri);
    final token=tokenResponse.body;
    // 发起 GET 请求
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      throw HttpException('HTTP error! status: ${response.statusCode}');
    }

    // 解析 JSON 数据
   final jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }finally{

    // 重置閒置計時器
    _startIdleTimer();
  }
}
/// 關閉連接
Future<void> disconnect() async {

  if (conn != null) {
    await conn!.close();
    conn = null;
    print('MySQL 連接已關閉');
  }
}// 啟動閒置計時器
void _startIdleTimer() {
  // 如果已有計時器，則取消
  _idleTimer?.cancel();

  // 設置計時器，每30秒沒有操作時斷開連接
  _idleTimer = Timer(Duration(seconds: idleTimeout), () {
    disconnect();
  });
}