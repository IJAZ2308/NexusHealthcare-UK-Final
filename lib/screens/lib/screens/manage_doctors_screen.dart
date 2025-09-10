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

  Future<void> _updateStatus(String doctorId, String status) async {
    await _dbRef.child(doctorId).update({'status': status});

    if (!mounted) return; // ✅ prevents context error

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Doctor status updated to $status")));
  }

  Future<void> _deleteDoctor(String doctorId) async {
    await _dbRef.child(doctorId).remove();

    if (!mounted) return; // ✅ prevents context error

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Doctor deleted")));
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
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email'] ?? ''}"),
                      Text("Specialty: ${data['specialty'] ?? ''}"),
                      Text("Status: ${data['status'] ?? 'pending'}"),
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
                            _updateStatus(data['doctorId'], "approved"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.orange),
                        onPressed: () =>
                            _updateStatus(data['doctorId'], "rejected"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
