import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class BedListScreen extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "hospitals",
  );

  BedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Beds")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No hospitals available"));
          }

          // Convert snapshot.value into a Map
          final Map<dynamic, dynamic> hospitals =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final hospitalList = hospitals.entries.toList();

          return ListView.builder(
            itemCount: hospitalList.length,
            itemBuilder: (context, index) {
              final hospitalId = hospitalList[index].key;
              final hospital = hospitalList[index].value as Map;

              final name = hospital['name'] ?? 'Unknown';
              final imageUrl = hospital['imageUrl'];
              final lat = (hospital['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (hospital['longitude'] as num?)?.toDouble() ?? 0.0;
              final availableBeds = hospital['availableBeds'] ?? 0;
              final phone = hospital['phone'] ?? '';
              final website = hospital['website'] ?? '';

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
                                          hospitalId,
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
              if (bedsNeeded > 0) {
                if (bedsNeeded <= availableBeds) {
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
                      const SnackBar(
                        content: Text("Not enough beds available."),
                      ),
                    );
                  }
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
