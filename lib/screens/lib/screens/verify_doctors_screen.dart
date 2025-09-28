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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenPendingDoctors();
  }

  /// 🔄 Realtime listener for pending doctors
  void _listenPendingDoctors() {
    _dbRef.orderByChild('status').equalTo('pending').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      List<Map<String, dynamic>> temp = [];
      if (data != null) {
        data.forEach((key, value) {
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

      if (mounted) {
        setState(() {
          pendingDoctors = temp;
          _loading = false;
        });
      }
    });
  }

  /// ✅ Approve doctor
  Future<void> _approveDoctor(String id, String role) async {
    await _dbRef.child(id).update({"status": "verified", "isVerified": true});

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(SnackBar(content: Text("Doctor approved ✅")));

    // Auto-redirect if this is the logged-in doctor
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == id) {
      if (role == 'labDoctor') {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const LabDoctorDashboard()),
        );
      } else if (role == 'consultingDoctor') {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const ConsultingDoctorDashboard()),
        );
      }
    }
  }

  /// ❌ Reject doctor
  Future<void> _rejectDoctor(String id) async {
    await _dbRef.child(id).update({"status": "rejected", "isVerified": false});

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(SnackBar(content: Text("Doctor rejected ❌")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Pending Doctors"),
        backgroundColor: Colors.red,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pendingDoctors.isEmpty
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
                    leading: const Icon(Icons.person, color: Colors.red),
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
