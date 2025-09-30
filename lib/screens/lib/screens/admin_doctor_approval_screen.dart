import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDoctorApprovalScreen extends StatefulWidget {
  const AdminDoctorApprovalScreen({super.key});

  @override
  State<AdminDoctorApprovalScreen> createState() =>
      _AdminDoctorApprovalScreenState();
}

class _AdminDoctorApprovalScreenState extends State<AdminDoctorApprovalScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'users',
  );
  List<Map<String, dynamic>> pendingDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenPendingDoctors(); // Use real-time listener
  }

  /// Real-time listener for pending doctors
  void _listenPendingDoctors() {
    _dbRef.orderByChild('status').equalTo('pending').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      List<Map<String, dynamic>> temp = [];
      if (data != null) {
        data.forEach((key, value) {
          final role = value['role'] ?? '';
          final status = value['status'] ?? '';
          if ((role == 'labDoctor' || role == 'consultingDoctor') &&
              status == 'pending') {
            temp.add({
              'id': key,
              'name': "${value['firstName'] ?? ''} ${value['lastName'] ?? ''}"
                  .trim(),
              'email': value['email'] ?? '',
              'license': value['license'] ?? '',
              'role': role,
            });
          }
        });
      }

      if (mounted) {
        setState(() {
          pendingDoctors = temp;
          _isLoading = false;
        });
      }
    });
  }

  /// Approve doctor
  Future<void> _approveDoctor(String doctorId) async {
    try {
      await _dbRef.child(doctorId).update({
        'status': 'approved',
        'isVerified': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doctor approved ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approval failed ❌: $e')));
    }
  }

  /// Reject doctor
  Future<void> _rejectDoctor(String doctorId) async {
    try {
      await _dbRef.child(doctorId).update({
        'status': 'rejected',
        'isVerified': false,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doctor rejected ❌')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rejection failed ❌: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Doctors")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingDoctors.isEmpty
          ? const Center(child: Text("No pending doctors 🎉"))
          : ListView.builder(
              itemCount: pendingDoctors.length,
              itemBuilder: (context, index) {
                final doctor = pendingDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.red),
                    title: Text(doctor['name']),
                    subtitle: Text(
                      "${doctor['email']}\nRole: ${doctor['role']}\nLicense: ${doctor['license']}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _approveDoctor(doctor['id']),
                          child: const Text("Approve"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectDoctor(doctor['id']),
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
