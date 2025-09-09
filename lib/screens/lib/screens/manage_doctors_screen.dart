// lib/screens/manage_doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'doctors',
  );

  Future<void> _updateVerification(String doctorId, bool value) async {
    await _dbRef.child(doctorId).update({'verified': value});
  }

  Future<void> _deleteDoctor(String doctorId) async {
    await _dbRef.child(doctorId).remove();
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
      appBar: AppBar(title: const Text("Manage Doctors")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No doctors found"));
          }

          final Map<dynamic, dynamic> doctorsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> doctors = doctorsMap.entries.map((
            e,
          ) {
            final data = e.value as Map<dynamic, dynamic>;
            data['doctorId'] = e.key;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final data = doctors[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email']}"),
                      Text("Specialty: ${data['specialty']}"),
                      Text("Verified: ${data['verified']}"),
                      if ((data['licenseUrl'] ?? '').isNotEmpty)
                        TextButton(
                          onPressed: () => _openUrl(data['licenseUrl']),
                          child: const Text(
                            "View License",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateVerification(data['doctorId'], true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateVerification(data['doctorId'], false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deleteDoctor(data['doctorId']),
                      ),
                    ],
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
