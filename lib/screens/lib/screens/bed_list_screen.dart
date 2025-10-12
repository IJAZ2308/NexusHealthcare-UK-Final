import 'dart:async';
import 'package:dr_shahin_uk/screens/booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class BedListScreen extends StatefulWidget {
  const BedListScreen({super.key});

  @override
  BedListScreenState createState() => BedListScreenState();
}

class BedListScreenState extends State<BedListScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'hospitals',
  );
  List<Map<String, dynamic>> hospitals = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
    _fetchHospitalsRealtime();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _fetchHospitalsRealtime() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      List<Map<String, dynamic>> tempHospitals = [];

      if (data != null) {
        final hospitalMap = data as Map<dynamic, dynamic>;
        hospitalMap.forEach((key, value) {
          Map<String, dynamic> hospital = Map<String, dynamic>.from(value);
          hospital['id'] = key;
          hospital['doctorId'] =
              value['doctorId'] ?? value['adminId'] ?? 'unknown';
          tempHospitals.add(hospital);
        });
      }

      if (_currentPosition != null) {
        tempHospitals = tempHospitals.where((hospital) {
          if (hospital['latitude'] != null && hospital['longitude'] != null) {
            double distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              hospital['latitude'],
              hospital['longitude'],
            );
            hospital['distance'] = (distance / 1000).toStringAsFixed(2);
            return distance <= 5000;
          }
          return false;
        }).toList();
      }

      setState(() {
        hospitals = tempHospitals;
      });
    });
  }

  Future<void> _initLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((Position position) {
          setState(() => _currentPosition = position);
          _fetchHospitalsRealtime();
        });
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMap(double lat, double lng) async =>
      _launchUrl("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

  Future<void> _launchCaller(String phoneNumber) async =>
      _launchUrl("tel:$phoneNumber");

  Future<void> _launchWebsite(String url) async => _launchUrl(url);

  int _getTotalBeds(Map<String, dynamic> hospital) {
    final beds = hospital['beds'];
    if (beds is Map) {
      return beds.values.fold(0, (prev, value) => prev + (value as int));
    }
    if (beds is int) return beds;
    return 0;
  }

  Widget _buildBedCount(Map<String, dynamic> hospital) {
    final beds = hospital['beds'];
    if (beds is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: beds.entries.map((entry) {
          final count = entry.value;
          return Text(
            "${entry.key.toUpperCase()} Beds: $count",
            style: TextStyle(
              fontSize: 14,
              color: count == 0 ? Colors.grey : Colors.black,
            ),
          );
        }).toList(),
      );
    } else if (beds != null) {
      return Text("Total Beds: $beds", style: const TextStyle(fontSize: 14));
    } else {
      return const Text("Beds: N/A", style: TextStyle(fontSize: 14));
    }
  }

  void _bookBed(Map<String, dynamic> hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(hospital: hospital),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Beds")),
      body: Column(
        children: [
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Your Location: (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: hospitals.isEmpty
                ? const Center(child: Text("No hospitals found nearby."))
                : ListView.builder(
                    itemCount: hospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = hospitals[index];
                      final totalBeds = _getTotalBeds(hospital);

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  hospital['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBedCount(hospital),
                                    if (hospital.containsKey('distance'))
                                      Text(
                                        "Distance: ${hospital['distance']} km",
                                      ),
                                    Text(
                                      "Contact: ${hospital['contact'] ?? 'N/A'}",
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.map,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _launchMap(
                                        hospital['latitude'],
                                        hospital['longitude'],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.phone,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _launchCaller(
                                        hospital['contact'] ?? "",
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.web,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () => _launchWebsite(
                                        hospital['website'] ?? "",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: totalBeds > 0
                                        ? Colors.blueAccent
                                        : Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.local_hotel,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    totalBeds > 0
                                        ? "Book a Bed"
                                        : "No Beds Available",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onPressed: totalBeds > 0
                                      ? () => _bookBed(hospital)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
