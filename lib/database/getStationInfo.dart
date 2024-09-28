import 'dart:convert'; // For JSON decoding
import 'dart:io'; // For file reading and writing
import 'package:http/http.dart' as http;

import 'getData.dart'; // For network requests

Future<List<Map<String, dynamic>>> fetchStationInfo(String stationId, String city) async {
  final tokenUri = Uri.parse('http://hidden.rsmn574.com:3920/token');

  // Construct the URL for the API request
  final String url = "https://tdx.transportdata.tw/api/advanced/v2/Bus/EstimatedTimeOfArrival/City/$city/PassThrough/Station/$stationId?\$t&\$format=JSON";

  try {
    // Connect to MySQL if necessary (assuming connMysql is defined elsewhere)
    await connMysql();

    // Fetch the token
    final tokenResponse = await http.get(tokenUri);
    if (tokenResponse.statusCode != 200) {
      throw HttpException('Failed to fetch token! Status: ${tokenResponse.statusCode}');
    }
    final token = tokenResponse.body;

    // Send the request to fetch bus arrival information
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    // Check the response status
    if (response.statusCode != 200) {
      throw HttpException('HTTP error! Status: ${response.statusCode}');
    }

    // Parse JSON data
    final List<dynamic> jsonData = jsonDecode(response.body); // Change to List<dynamic>

    print('JSON fetched successfully: $jsonData');

    // Convert JSON data to List<Map<String, dynamic>> before returning
    return jsonData.map((item) => item as Map<String, dynamic>).toList();

  } catch (e) {
    print('Error occurred: $e');
    return []; // Return an empty list in case of error
  }
}
