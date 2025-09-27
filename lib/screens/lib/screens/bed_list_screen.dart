import 'dart:async';
import 'package:dr_shahin_uk/screens/booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class BedListScreen extends StatefulWidget {
  const BedListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BedListScreenState createState() => _BedListScreenState();
}

class _BedListScreenState extends State<BedListScreen> {
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
        Map<dynamic, dynamic> hospitalMap = data as Map<dynamic, dynamic>;
        hospitalMap.forEach((key, value) {
          Map<String, dynamic> hospital = Map<String, dynamic>.from(value);
          hospital['id'] = key;

          // Add a doctorId if your hospital structure has doctor info
          hospital['doctorId'] =
              value['doctorId'] ?? value['adminId'] ?? 'unknown';

          tempHospitals.add(hospital);
        });
      }

      // Filter by distance if location is available
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
            return distance <= 5000; // 5 km range
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
    if (!serviceEnabled) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((Position position) {
          setState(() {
            _currentPosition = position;
          });
          _fetchHospitalsRealtime(); // refresh hospital distances
        });
  }

  Future<void> _launchMap(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch map';
    }
  }

  Future<void> _launchCaller(String phoneNumber) async {
    final url = "tel:$phoneNumber";
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not make call';
    }
  }

  Future<void> _launchWebsite(String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not open website';
    }
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
                      var hospital = hospitals[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(hospital['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Beds: ${hospital['beds'] ?? 'N/A'}"),
                              if (hospital.containsKey('distance'))
                                Text("Distance: ${hospital['distance']} km"),
                              Text("Contact: ${hospital['contact'] ?? 'N/A'}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.map, color: Colors.blue),
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
                                onPressed: () =>
                                    _launchCaller(hospital['contact'] ?? ""),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.web,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _launchWebsite(hospital['website'] ?? ""),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Pass doctorId to BookingScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookingScreen(hospital: hospital),
                              ),
                            );
                          },
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
