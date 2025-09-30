import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class OsmMapScreen extends StatefulWidget {
  const OsmMapScreen({super.key});

  @override
  State<OsmMapScreen> createState() => _OsmMapScreenState();
}

class _OsmMapScreenState extends State<OsmMapScreen> {
  Position? _currentPosition;
  final List<Marker> _markers = [];
  final double _radiusKm = 10; // 10 km radius
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("hospitals");

  @override
  void initState() {
    super.initState();
    _initLocationAndHospitals();
  }

  Future<void> _initLocationAndHospitals() async {
    try {
      // Get current location
      final pos = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = pos;
      });

      // Get hospitals from Firebase
      final snapshot = await _dbRef.get();
      final data = snapshot.value as Map?;

      if (data == null) return;

      for (var entry in data.entries) {
        final hospital = entry.value as Map;
        final lat = (hospital['lat'] as num?)?.toDouble();
        final lng = (hospital['lng'] as num?)?.toDouble();
        final name = hospital['name'] ?? "Unknown";
        final beds = hospital['availableBeds'] ?? 0;

        if (lat != null && lng != null) {
          // Calculate distance in km
          final distance =
              Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                lat,
                lng,
              ) /
              1000;

          // Choose marker color based on distance
          final isNearby = distance <= _radiusKm;
          final markerColor = isNearby ? Colors.red : Colors.grey;

          _markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 200,
              height: 60,
              child: GestureDetector(
                onTap: () => _showHospitalPopup(name, beds, lat, lng, distance),
                child: Icon(Icons.local_hospital, color: markerColor, size: 30),
              ),
            ),
          );
        }
      }

      setState(() {});
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showHospitalPopup(
    String name,
    int beds,
    double lat,
    double lng,
    double distance,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Available Beds: $beds"),
            Text("Distance: ${distance.toStringAsFixed(2)} km"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text("Directions"),
            onPressed: () => _openMap(lat, lng),
          ),
        ],
      ),
    );
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open maps.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hospitals on Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              // User location marker
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              ..._markers,
            ],
          ),
        ],
      ),
    );
  }
}
