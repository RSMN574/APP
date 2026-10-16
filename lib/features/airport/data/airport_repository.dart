import 'get_flight.dart';

/// Entry point for airport data so state and pages do not call the
/// top-level TDX helpers directly.
class AirportRepository {
  const AirportRepository();

  Future<List<dynamic>> metar(String location) => getAirportMETAR(location);

  Future<List<dynamic>> arrivals(String airport) =>
      getAirportFIDSArrival(airport);

  Future<List<dynamic>> departures(String airport) =>
      getAirportFIDSDeparture(airport);

  Future<List<dynamic>> flight(String airlineId, String flightNumber) =>
      getFlight(airlineId, flightNumber);

  Future<Map<String, dynamic>> airportInfo(String code) =>
      AirportService.loadAirportData(code);
}
