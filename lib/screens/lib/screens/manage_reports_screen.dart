// lib/screens/manage_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref().child(
    'reports',
  );
  final DatabaseReference _patientsRef = FirebaseDatabase.instance.ref().child(
    'patients',
  );

  final Map<String, String> _patientNames = {};
  Map<String, dynamic> _reportsByPatient = {};
  bool _loading = true;

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadPatientNamesAndReports();
  }

  Future<void> _loadPatientNamesAndReports() async {
    final patientsSnap = await _patientsRef.get();
    final reportsSnap = await _reportsRef.get();

    if (!mounted) return;

    // Load patient names
    if (patientsSnap.exists && patientsSnap.value != null) {
      final data = Map<String, dynamic>.from(patientsSnap.value as Map);
      data.forEach((key, value) {
        _patientNames[key] = value['name'] ?? 'Unknown';
      });
    }

    // Load reports
    if (reportsSnap.exists && reportsSnap.value != null) {
      setState(() {
        _reportsByPatient = Map<String, dynamic>.from(reportsSnap.value as Map);
        _loading = false;
      });
    } else {
      setState(() {
        _reportsByPatient = {};
        _loading = false;
      });
    }
  }

  Future<void> _openReport(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open report")));
    }
  }

  // Filter reports based on search query
  Map<String, dynamic> get _filteredReports {
    if (_searchQuery.isEmpty) return _reportsByPatient;

    final filtered = <String, dynamic>{};

    _reportsByPatient.forEach((patientId, reports) {
      final patientName = _patientNames[patientId] ?? patientId;
      final reportsMap = Map<String, dynamic>.from(reports);
      final filteredReports = <String, dynamic>{};

      reportsMap.forEach((reportId, reportData) {
        final report = Map<String, dynamic>.from(reportData);
        final title = report['title']?.toString().toLowerCase() ?? '';
        if (patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            title.contains(_searchQuery.toLowerCase())) {
          filteredReports[reportId] = report;
        }
      });

      if (filteredReports.isNotEmpty) {
        filtered[patientId] = filteredReports;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Reports")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search by patient name or report title",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredReports.isEmpty
                      ? const Center(child: Text("No reports found"))
                      : ListView(
                          children: _filteredReports.entries.map((entry) {
                            final patientId = entry.key;
                            final patientName =
                                _patientNames[patientId] ?? patientId;
                            final reports = Map<String, dynamic>.from(
                              entry.value,
                            );

                            return ExpansionTile(
                              title: Text(patientName),
                              children: reports.entries.map((repEntry) {
                                final report = Map<String, dynamic>.from(
                                  repEntry.value,
                                );
                                return ListTile(
                                  title: Text(
                                    report['title'] ?? 'Untitled Report',
                                  ),
                                  subtitle: Text(
                                    "Uploaded by: ${report['uploadedBy'] ?? 'Unknown'}\nDate: ${report['uploadedAt'] ?? 'Unknown'}",
                                  ),
                                  trailing: report['url'] != null
                                      ? IconButton(
                                          icon: const Icon(Icons.open_in_new),
                                          onPressed: () =>
                                              _openReport(report['url']),
                                        )
                                      : null,
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
