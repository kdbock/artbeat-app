import 'dart:convert';

import 'package:http/http.dart' as http;

class DirectionsService {
  final String? _apiKey;

  DirectionsService({String? apiKey}) : _apiKey = apiKey;

  Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination,
  ) async {
    final apiKey = _apiKey ?? 'YOUR_GOOGLE_MAPS_API_KEY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load directions');
    }
  }
}
