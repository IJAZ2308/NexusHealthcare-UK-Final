// lib/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  Future<void> _updateVerification(String uid, bool value) async {
    await _dbRef.child(uid).update({'isVerified': value});
  }

  Future<void> _openLicense(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.orderByChild('role').equalTo('doctor').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No doctors found"));
          }

          final Map<dynamic, dynamic> doctorsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> doctors = doctorsMap.entries.map((
            e,
          ) {
            final data = e.value as Map<dynamic, dynamic>;
            data['uid'] = e.key;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final data = doctors[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email']}"),
                      Text("Verified: ${data['isVerified']}"),
                      if ((data['licenseUrl'] ?? '').isNotEmpty)
                        TextButton(
                          onPressed: () => _openLicense(data['licenseUrl']),
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
                        onPressed: () => _updateVerification(data['uid'], true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateVerification(data['uid'], false),
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
