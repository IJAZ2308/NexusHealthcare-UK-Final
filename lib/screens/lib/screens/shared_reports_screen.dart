// lib/screens/patient/shared_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedReportsScreen extends StatefulWidget {
  const SharedReportsScreen({super.key});

  @override
  State<SharedReportsScreen> createState() => _SharedReportsScreenState();
}

class _SharedReportsScreenState extends State<SharedReportsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Map<String, dynamic> _sharedReports = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSharedReports();
  }

  Future<void> _fetchSharedReports() async {
    final userId = _auth.currentUser!.uid;
    final snapshot = await _db.child('patients/$userId/sharedReports').get();

    if (snapshot.exists && snapshot.value != null) {
      if (!mounted) return;
      setState(() {
        _sharedReports = Map<String, dynamic>.from(snapshot.value as Map);
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _sharedReports = {};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shared Reports")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sharedReports.isEmpty
          ? const Center(child: Text("No reports shared yet"))
          : ListView(
              children: _sharedReports.entries.map((entry) {
                final report = Map<String, dynamic>.from(entry.value);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: const Text("Doctor Report"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report['doctorNotes'] != null &&
                            report['doctorNotes'].isNotEmpty)
                          Text("Notes: ${report['doctorNotes']}"),
                        if (report['timestamp'] != null)
                          Text(
                            "Date: ${DateTime.parse(report['timestamp']).toLocal().toString().split('.')[0]}",
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        final url = report['reportUrl'];
                        if (url != null && await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
