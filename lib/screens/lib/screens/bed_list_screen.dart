import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'osm_map_screen.dart'; // Make sure this file exists and has OsmMapScreen widget.

class BedListScreen extends StatefulWidget {
  const BedListScreen({super.key});

  @override
  State<BedListScreen> createState() => _BedListScreenState();
}

class _BedListScreenState extends State<BedListScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("hospitals");

  Position? _currentPosition;
  bool _loadingLocation = true;
  final double _searchRadiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied."),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Beds Near You")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.map),
        label: const Text("Map View"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OsmMapScreen(
                hospitals: [],
                userLocation: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : LatLng(0.0, 0.0),
              ),
            ),
          );
        },
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getCurrentLocation,
              child: StreamBuilder<DatabaseEvent>(
                stream: _dbRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No hospitals available"));
                  }

                  final Map<dynamic, dynamic> hospitals =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  final filteredHospitals = hospitals.entries
                      .map((entry) {
                        final hospital = entry.value as Map;
                        final lat = (hospital['latitude'] as num?)?.toDouble();
                        final lng = (hospital['longitude'] as num?)?.toDouble();

                        if (lat == null || lng == null) return null;

                        final distance = _calculateDistance(lat, lng);
                        return {
                          'id': entry.key,
                          'data': hospital,
                          'distance': distance,
                        };
                      })
                      .where(
                        (e) => e != null && e['distance'] <= _searchRadiusKm,
                      )
                      .toList();

                  filteredHospitals.sort(
                    (a, b) => a!['distance'].compareTo(b!['distance']),
                  );

                  if (filteredHospitals.isEmpty) {
                    return const Center(
                      child: Text("No hospitals found nearby."),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredHospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = filteredHospitals[index]!;
                      final data = hospital['data'] as Map;
                      final name = data['name'] ?? 'Unknown';
                      final imageUrl = data['imageUrl'];
                      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
                      final lng =
                          (data['longitude'] as num?)?.toDouble() ?? 0.0;
                      final availableBeds = data['availableBeds'] ?? 0;
                      final phone = data['phone'] ?? '';
                      final website = data['website'] ?? '';
                      final distance = hospital['distance'] as double;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(height: 180, color: Colors.grey),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text("Available Beds: $availableBeds"),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Distance: ${distance.toStringAsFixed(2)} km",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _openMap(lat, lng);
                                        },
                                        icon: const Icon(Icons.directions),
                                        label: const Text("Get Directions"),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: availableBeds > 0
                                            ? () {
                                                _bookBed(
                                                  context,
                                                  hospital['id'],
                                                  availableBeds,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(Icons.local_hospital),
                                        label: const Text("Book Bed"),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: phone.isNotEmpty
                                            ? () {
                                                _callHospital(phone);
                                              }
                                            : null,
                                        icon: const Icon(Icons.phone),
                                        label: const Text("Call Hospital"),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: website.isNotEmpty
                                            ? () {
                                                _openWebsite(website);
                                              }
                                            : null,
                                        icon: const Icon(Icons.public),
                                        label: const Text("Visit Website"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  void _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _bookBed(BuildContext context, String hospitalId, int availableBeds) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Book Bed"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter number of beds needed",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final bedsNeeded = int.tryParse(controller.text) ?? 0;
              if (bedsNeeded > 0 && bedsNeeded <= availableBeds) {
                await FirebaseDatabase.instance
                    .ref()
                    .child("hospitals/$hospitalId")
                    .update({'availableBeds': availableBeds - bedsNeeded});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bed booked successfully!")),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Not enough beds available.")),
                  );
                }
              }
            },
            child: const Text("Book"),
          ),
        ],
      ),
    );
  }

  void _callHospital(String phone) async {
    final uri = Uri(scheme: "tel", path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
