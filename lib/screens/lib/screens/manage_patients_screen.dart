import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({super.key});

  @override
  State<ManagePatientsScreen> createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  final DatabaseReference _patientsRef = FirebaseDatabase.instance.ref().child(
    'patients',
  ); // Your patients node
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance
      .ref()
      .child('appointments'); // Your appointments node

  void _updateVerification(String patientId, bool isVerified) {
    _patientsRef.child(patientId).update({'verified': isVerified}).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Patient ${isVerified ? 'verified' : 'rejected'} successfully!',
            ),
          ),
        );
      }
    });
  }

  void _deletePatient(String patientId) {
    _patientsRef.child(patientId).remove().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted successfully!')),
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPatients() async {
    final patientsSnapshot = await _patientsRef.get();
    final appointmentsSnapshot = await _appointmentsRef.get();

    Map<dynamic, dynamic> patientsMap = {};
    if (patientsSnapshot.value != null) {
      patientsMap = patientsSnapshot.value as Map<dynamic, dynamic>;
    }

    Map<dynamic, dynamic> appointmentsMap = {};
    if (appointmentsSnapshot.value != null) {
      appointmentsMap = appointmentsSnapshot.value as Map<dynamic, dynamic>;
    }

    List<Map<String, dynamic>> patientsList = [];

    for (var entry in patientsMap.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      data['patientId'] = entry.key;

      // If the patient's name is "Unknown", try to find from appointments
      if (data['name'] == "Unknown") {
        for (var appt in appointmentsMap.values) {
          final apptData = Map<String, dynamic>.from(appt);
          if (apptData['patientId'] == entry.key &&
              apptData['patientName'] != null) {
            data['name'] = apptData['patientName'];
            break;
          }
        }
      }

      patientsList.add(data);
    }

    return patientsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Patients')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No patients found"));
          }

          final patients = snapshot.data!;

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final data = patients[index];

              double averageRating = 0;
              if (data['numberOfReviews'] != null &&
                  data['numberOfReviews'] > 0 &&
                  data['totalReviews'] != null) {
                averageRating = data['totalReviews'] / data['numberOfReviews'];
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name'] ?? "Unknown"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email'] ?? 'N/A'}"),
                      Text("Verified: ${data['verified'] ?? false}"),
                      if (averageRating > 0)
                        Text("Rating: ${averageRating.toStringAsFixed(1)}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateVerification(data['patientId'], true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateVerification(data['patientId'], false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deletePatient(data['patientId']),
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
