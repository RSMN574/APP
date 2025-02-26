import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Const/regularConst.dart';
import '../getData.dart'; // 用于网络请求
Future<dynamic> fetchTrain(int trainNo,DateTime date) async {


  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  int _trainNo=trainNo;
  var _date=dateFormat.format(date) ;
  var url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/TrainNo/$_trainNo/TrainDate/$_date?%24format=JSON";

  try {
    await  connMysql();
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
Map<String, dynamic>  jsonData = await jsonDecode(response.body)[0];

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}
// Future<List<dynamic>> fetchTrainStation(String station) async {
//
//
//
//   String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/${station}?%24format=JSON";
//   try {
//     await  connMysql();
//     final tokenResponse = await http.get(tokenUri);
//     final token=tokenResponse.body;
//     // 发起 GET 请求
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'accept': 'application/json',
//       },
//     );
//
//     // 检查响应状态
//     if (response.statusCode != 200) {
//       throw HttpException('HTTP error! status: ${response.statusCode}');
//     }
//
//     // 解析 JSON 数据
//     List<dynamic>  jsonData = await jsonDecode(response.body);
// print(jsonData);
//     // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
//     // 这里你可以根据你的需求来构建 SQL 语句，例如：
//     // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
//
//     return jsonData;
//   } catch (e) {
//     print('Error occurred: $e');
//   }
//   return [];
// }


Future<List<dynamic>> fetchTrainStation(String stationID,DateTime date) async {

  DateTime now = DateTime.now();
  DateTime targetTime = (date);

// 計算前後 30 分鐘範圍
  DateTime startRange = now.subtract(Duration(minutes: 30));
  DateTime endRange = now.add(Duration(minutes: 30));

// 判斷 targetTime 是否在範圍內
  bool isWithinRange = targetTime.isAfter(startRange) && targetTime.isBefore(endRange);
  List<Map<String, dynamic>> trainLiveBoard=[];
  if (isWithinRange) {
    trainLiveBoard=await  fetchTrainLiveBoard(stationID);
    print("時間在前後 30 分鐘內");
  } else {
    print("時間超出範圍");
  }

  //https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/StationLiveBoard/Station/3300?%24format=JSON
  String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/Station/$stationID/${DateFormat('yyyy-MM-dd').format(date)}?%24format=JSON";
  try {
    await  connMysql();
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
    List<dynamic>  jsonData = await jsonDecode(response.body);
    print(jsonData);
// 合併兩個 List
//     List<Map> mergedData = trainLiveBoard.map((trainLive) {
//       // 將 trainLive 的 TrainNo 轉成字串
//       String liveTrainNo = trainLive["TrainNo"].toString();
//
//       // 在 jsonData 中尋找 TrainNo 相符的項目
//       var matchingJson = jsonData.firstWhere(
//             (jsonTrain) => jsonTrain["TrainNo"].toString() == liveTrainNo,
//         orElse: () => null,
//       );
//
//       // 若找到對應資料，則合併兩個 Map，否則僅保留 trainLive 資料
//       return matchingJson != null ? {...trainLive, ...matchingJson} : trainLive;
//     }).toList();
    List<dynamic> mergedData = jsonData.map((i) {
      // 在 trainLiveBoard 中尋找相同 TrainNo 的 DelayTime
      Map<String, dynamic>? matchedTrain = trainLiveBoard.firstWhere(
            (item) => item["TrainNo"].toString() == i["TrainNo"].toString(),
        orElse: () => {"DelayTime": null}, // 若無對應資料，預設為 null
      );

      // 新增 DelayTime 屬性
      return {
        ...i, // 保留 jsonData 原本的內容
        "DelayTime": matchedTrain["DelayTime"] != null
            ? int.tryParse(matchedTrain["DelayTime"].toString()) ?? 0
            : 0, // 若 DelayTime 為 null，則預設為 0
      };
    }).toList();

print(mergedData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return mergedData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
//取得指定[日期],[起迄站間]之站間時刻表資料
Future<List<dynamic>> fetchTrainRoute(departurePosition,destinationPosition,time) async {
  print(time);
  // 对参数进行 URL 编码
  String encodedDeparture = Uri.encodeComponent(departurePosition);
  String encodedDestination = Uri.encodeComponent(destinationPosition);
  String encodedTime = Uri.encodeComponent(time);
 // String url="https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/DailyTrainTimetable/OD/Inclusive/$departureID/to/$destinationID/$date?%24&%24format=JSON";
  String url="https://tdx.transportdata.tw/api/maas/routing?origin=$encodedDeparture&destination=$encodedDestination&gc=0.0&top=10&transit=4&transfer_time=5%2C60&depart=$encodedTime&first_mile_mode=0&last_mile_mode=0";

  try {


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
    Map<String, dynamic>  jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData["data"]["routes"];
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
//取得列車即時準點/延誤時間資料。
Future<List<dynamic>> fetchLiveTrainDelay(String trainNo) async {


  String filter = Uri.encodeComponent("TrainNo eq '$trainNo'");
  String url = "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveTrainDelay?\$filter=$filter&\$format=JSON";

  try {
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
    List<dynamic> jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
    print(jsonData);
    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}

Future<List<Map<String, dynamic>>> fetchTrainLiveBoard(String stationID) async {


  String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/$stationID?%24&%24format=JSON";
  try {
    await  connMysql();
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
    List<dynamic>  jsonData = await jsonDecode(response.body);
    List<Map<String, dynamic>> extractedData = jsonData.map((train) {
      return {
        "TrainNo": train["TrainNo"],
        "DelayTime": train["DelayTime"]
      };
    }).toList();
    print(extractedData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return extractedData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}