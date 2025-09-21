import 'package:dr_shahin_uk/screens/lib/screens/doctor_dashboard_consulting.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor_dashboard_lab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyPending extends StatefulWidget {
  const VerifyPending({super.key});

  @override
  State<VerifyPending> createState() => _VerifyPendingState();
}

class _VerifyPendingState extends State<VerifyPending> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'users',
  );
  List<Map<String, dynamic>> pendingDoctors = [];

  @override
  void initState() {
    super.initState();
    _loadPendingDoctors();
  }

  Future<void> _loadPendingDoctors() async {
    final snapshot = await _dbRef
        .orderByChild('status')
        .equalTo('pending')
        .get();

    List<Map<String, dynamic>> temp = [];
    if (snapshot.value != null) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if ((value['role'] == 'labDoctor' ||
                value['role'] == 'consultingDoctor') &&
            value['status'] == 'pending') {
          temp.add({
            "id": key,
            "name": value["name"] ?? "",
            "email": value["email"] ?? "",
            "role": value["role"] ?? "",
          });
        }
      });
    }

    if (!mounted) return;
    setState(() {
      pendingDoctors = temp;
    });
  }

  /// Approve doctor & redirect automatically if logged-in user
  Future<void> _approveDoctor(String id, String role) async {
    await _dbRef.child('$id/status').set('verified');
    await _dbRef.child('$id/isVerified').set(true);

    _loadPendingDoctors();

    // If the currently logged-in doctor is approved, redirect to dashboard
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == id) {
      if (role == 'labDoctor') {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const LabDoctorDashboard()),
        );
      } else if (role == 'consultingDoctor') {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const ConsultingDoctorDashboard()),
        );
      }
    }
  }

  Future<void> _rejectDoctor(String id) async {
    await _dbRef.child('$id/status').set('rejected');
    _loadPendingDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Pending Doctors")),
      body: pendingDoctors.isEmpty
          ? const Center(child: Text("No pending doctors"))
          : ListView.builder(
              itemCount: pendingDoctors.length,
              itemBuilder: (context, index) {
                final doc = pendingDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(doc["name"]),
                    subtitle: Text("${doc["email"]}\nRole: ${doc["role"]}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () =>
                              _approveDoctor(doc["id"], doc["role"]),
                          child: const Text("Approve"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectDoctor(doc["id"]),
                          child: const Text("Reject"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
