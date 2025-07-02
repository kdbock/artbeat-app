#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Simple script to test Google Maps API key
Future<void> main() async {
  const apiKey = 'AIzaSyBvmSCvenoo9u-eXNzKm_oDJJJjC0MbqHA';

  print('🔍 Testing Google Maps API key...');
  print('🔑 API Key: ${apiKey.substring(0, 20)}...');

  // Test Maps Static API
  final staticUrl =
      'https://maps.googleapis.com/maps/api/staticmap'
      '?size=400x400'
      '&center=35.7596,-79.0193'
      '&zoom=10'
      '&key=$apiKey';

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(staticUrl));
    final response = await request.close();

    print('📍 Static Maps API Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ Static Maps API is working!');
    } else {
      final body = await response.transform(utf8.decoder).join();
      print('❌ Static Maps API failed: $body');
    }

    client.close();
  } catch (e) {
    print('❌ Error testing Static Maps API: $e');
  }

  // Test Geocoding API
  final geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=Raleigh,NC'
      '&key=$apiKey';

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(geocodeUrl));
    final response = await request.close();

    print('🌍 Geocoding API Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data['status'] == 'OK') {
        print('✅ Geocoding API is working!');
      } else {
        print(
          '❌ Geocoding API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}',
        );
      }
    }

    client.close();
  } catch (e) {
    print('❌ Error testing Geocoding API: $e');
  }
}
