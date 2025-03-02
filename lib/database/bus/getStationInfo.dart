import 'dart:convert'; // For JSON decoding
import 'dart:io'; // For file reading and writing
import 'package:http/http.dart' as http;

import '../../Const/regularConst.dart';
import '../getData.dart'; // For network requests

Future<List<Map<String, dynamic>>> fetchStationInfo(List<String> stationIds, String city) async {


  try {
    // Connect to MySQL if necessary (assuming connMysql is defined elsewhere)
    await connMysql();

    // Fetch the token
    final tokenResponse = await http.get(tokenUri);
    if (tokenResponse.statusCode != 200) {
      throw HttpException('Failed to fetch token! Status: ${tokenResponse.statusCode}');
    }
    final token = tokenResponse.body;

    // Generate all requests for each station ID
    List<Future<List<Map<String, dynamic>>>> requests = stationIds.map((stationId) async {
      final String url = "https://tdx.transportdata.tw/api/advanced/v2/Bus/EstimatedTimeOfArrival/City/$city/PassThrough/Station/$stationId?\$t&\$format=JSON";

      // Fetch data for the specific station ID
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      // Check the response status
      if (response.statusCode != 200) {
        throw HttpException('HTTP error for StationID $stationId! Status: ${response.statusCode}');
      }

      // Parse and return JSON data
      final List<dynamic> jsonData = jsonDecode(response.body);

// Add the 'type' field to each item
      final List<Map<String, dynamic>> modifiedData = jsonData.map((item) {
        final modifiedItem = Map<String, dynamic>.from(item);
        modifiedItem['StationID'] = stationId; // 新增 type 字段，值为 stationId
        return modifiedItem;
      }).toList();

      // print('JSON fetched successfully for StationID $stationId: $modifiedData');




      return modifiedData.map((item) => item).toList();
    }).toList();

    // Wait for all requests to complete
    List<List<Map<String, dynamic>>> results = await Future.wait(requests);

    // Flatten the list of lists into a single list
    return results.expand((element) => element).toList();

  } catch (e) {
    print('Error occurred: $e');
    return []; // Return an empty list in case of error
  }
}
