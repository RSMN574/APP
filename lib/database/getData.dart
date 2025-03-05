import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:com.rsmn574.app/bus.dart';

import '../Const/regularConst.dart';
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


  // 如果連接已存在，則避免重複連接
  if (conn != null) {

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
Future<List<Map<String, dynamic>>> GetBusInfo({  required int routeid,required String city,} ) async {
   sum = 0;
  List<Map<String, dynamic>> routeName = [];

     routeID = routeid;





  await connMysql(); // 連接資料庫

  var query = 'SELECT Stops FROM Bus.Bus_${city}_Route_Stop WHERE Routeid = $routeid';
  jsonData = await mysqlSelect(query);

  for (var i in jsonData) {

    sum=(sum!+json.decode(i['Stops']).length) as int?;
    routeName.add(i);
  }

  // 重置閒置計時器
  _startIdleTimer();

  return routeName;
}

Future<List<Map<String, dynamic>>> mysqlSelect(String query) async {
  List<Map<String, dynamic>> jsonArray = [];

  try {
    // 确保数据库连接
    await connMysql(); // 連接資料庫

    // 执行查询
    var result = await conn!.execute(query);

    // 处理查询结果
    for (final row in result.rows) {
      jsonArray.add(row.assoc());
    }
  } catch (e) {
    print("Error during mysqlSelect: $e");

    // 如果连接关闭，则尝试重连并重试查询
    if (e.toString().contains("connection closed")) {
      print("Reconnecting to database...");
      await connMysql();
      try {
        var result = await conn!.execute(query);
        for (final row in result.rows) {
          jsonArray.add(row.assoc());
        }
      } catch (innerError) {
        print("Failed to execute query after reconnection: $innerError");
      }
    }
  } finally {
    // 重置闲置计时器
    _startIdleTimer();
  }

  return jsonArray;
}

Future<bool> checkConnection() async {
  try {
    // 執行一個輕量級查詢來驗證連線
    await conn?.execute('SELECT 1');

  } catch (e) {
    print("Database connection lost, reconnecting...");
     await connMysql();  // 重新連線
    return false;  // 連線失敗
  }
  return true;  // 連線正常
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

Future<List<Map<String, dynamic>>> GetBusStopInfo(String stopName ,String city,) async {

  await connMysql(); // 連接資料庫


  var query =  "SELECT  StationID,StationPosition FROM Bus.Bus_${city}_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '$stopName'";
  List<Map<String, dynamic>> stopInfo=[];

  jsonData=await mysqlSelect(query);
  List<dynamic>data=await mysqlSelect(query);

  for(var i in data){
    stopInfo.add(i);
  }

  // 重置閒置計時器
  _startIdleTimer();


  return stopInfo ;
}


Future<dynamic> fetchByUrl(String url, {dynamic other}) async {


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
    // print('MySQL 連接已關閉');
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

Future<List<Map<String, dynamic>>> fetchTrainStationFacility(String stationID) async {
  try {
    // 连接数据库
    await connMysql();


    String queryFacility = "SELECT * FROM Train.Station_StationFacility WHERE StationID = $stationID;";
    String queryStation = "SELECT * FROM Train.Train_Station WHERE StationID = $stationID;";
    // 查询设施数据
    List<Map<String, dynamic>> facilityData = await mysqlSelect(queryFacility);

    // 查询车站数据
    List<Map<String, dynamic>> stationData = await mysqlSelect(queryStation);

    // 打印调试信息



    // 合并两个查询结果
    List<Map<String, dynamic>> combinedData = [
      ...facilityData,
      ...stationData,
    ];

    // 重置闲置计时器
    _startIdleTimer();
    print("combinedData $combinedData");
    return combinedData;
  } catch (e, stackTrace) {
    // 捕获并记录错误
    print("Error fetching station facilities: $e");
    print(stackTrace);

    // 返回空列表以防止程序崩溃
    return [];
  }
}
