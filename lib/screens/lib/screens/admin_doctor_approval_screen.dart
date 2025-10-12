import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // Fix for kDebugMode
import 'package:http/http.dart' as http;

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
    _listenPendingDoctors();
  }

  /// Real-time listener for pending doctors
  void _listenPendingDoctors() {
    _dbRef
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (kDebugMode) print('Firebase snapshot data: $data');

            List<Map<String, dynamic>> temp = [];

            if (data != null) {
              data.forEach((key, value) {
                if (value is Map<dynamic, dynamic>) {
                  final role = value['role'] ?? '';
                  final status = value['status'] ?? '';

                  if (kDebugMode) {
                    print('User $key with role: $role, status: $status');
                  }

                  if ((role == 'labDoctor' || role == 'consultingDoctor') &&
                      status == 'pending') {
                    temp.add({
                      'id': key,
                      'name':
                          "${value['firstName'] ?? ''} ${value['lastName'] ?? ''}"
                              .trim(),
                      'email': value['email'] ?? '',
                      'license': value['license'] ?? '',
                      'role': role,
                    });
                  }
                }
              });
            }

            if (mounted) {
              setState(() {
                pendingDoctors = temp;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            if (kDebugMode) print('Firebase listener error: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
  }

  /// Call Cloud Function to send notification
  Future<void> _sendNotification(String doctorId, String status) async {
    try {
      final url =
          'https://YOUR_CLOUD_FUNCTION_URL/notifyDoctor'; // Replace with your function URL
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorId': doctorId, 'status': status}),
      );
    } catch (e) {
      if (kDebugMode) print('Error calling Cloud Function: $e');
    }
  }

  /// Approve doctor
  Future<void> _approveDoctor(String doctorId) async {
    try {
      await _dbRef.child(doctorId).update({
        'status': 'approved',
        'isVerified': true,
      });

      await _sendNotification(doctorId, 'approved');

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

      await _sendNotification(doctorId, 'rejected');

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
