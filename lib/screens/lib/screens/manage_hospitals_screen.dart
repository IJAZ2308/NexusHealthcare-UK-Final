// lib/screens/manage_hospitals_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageHospitalsScreen extends StatefulWidget {
  const ManageHospitalsScreen({super.key});

  @override
  State<ManageHospitalsScreen> createState() => _ManageHospitalsScreenState();
}

class _ManageHospitalsScreenState extends State<ManageHospitalsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'hospitals',
  );

  Future<void> _deleteHospital(String hospitalId) async {
    await _dbRef.child(hospitalId).remove();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Hospitals")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No hospitals found"));
          }

          final Map<dynamic, dynamic> hospitalsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> hospitals = hospitalsMap.entries
              .map((e) {
                final data = e.value as Map<dynamic, dynamic>;
                data['hospitalId'] = e.key;
                return data;
              })
              .toList();

          return ListView.builder(
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final data = hospitals[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(
                          data['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : null,
                  title: Text(data['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Available Beds: ${data['availableBeds']}"),
                      Text("Phone: ${data['phone']}"),
                      TextButton(
                        onPressed: () => _openUrl(data['website']),
                        child: const Text(
                          "Visit Website",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteHospital(data['hospitalId']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
