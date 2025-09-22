import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<Position?> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return await Geolocator.getCurrentPosition(
    // ignore: deprecated_member_use
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<List<Map<String, dynamic>>> fetchNearbyHospitalsOSM({
  required double lat,
  required double lon,
  int radiusMeters = 5000,
}) async {
  final query = Uri.encodeComponent(
    '[out:json];node(around:$radiusMeters,$lat,$lon)[amenity=hospital];out;',
  );
  final url = Uri.parse('https://overpass-api.de/api/interpreter?data=$query');

  final resp = await http.get(url);
  if (resp.statusCode != 200) throw Exception('Overpass error');

  final data = json.decode(resp.body);
  final elements = (data['elements'] as List<dynamic>?) ?? [];

  return elements.map((e) {
    final tags = e['tags'] ?? {};
    return {
      'name': tags['name'] ?? 'Unknown Hospital',
      'address': tags['addr:street'] ?? '',
      'lat': e['lat'],
      'lng': e['lon'],
    };
  }).toList();
}

double calculateDistanceKm(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
}
