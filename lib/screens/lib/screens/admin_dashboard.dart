import 'package:dr_shahin_uk/screens/lib/screens/verify_doctors_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // ✅ Used for date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; // ✅ Used for FCM HTTP requests
import 'dart:convert'; // ✅ Used for JSON encoding HTTP requests

import 'manage_doctors_screen.dart';
import 'manage_patients_screen.dart';
import 'manage_hospitals_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  int totalDoctors = 0;
  int totalPatients = 0;
  int totalHospitals = 0;
  int totalAppointments = 0;
  int pendingDoctors = 0;

  Map<String, dynamic> hospitals = {};
  Map<String, dynamic> doctors = {};

  List<Map<String, dynamic>> appointments = [];
  bool _isLoadingAppointments = true; // ✅ Used in loading indicator
  final int _selectedFilter = 0; // 0=All, 1=Upcoming, 2=Cancelled, 3=Completed
  final String _searchQuery = ""; // Search filter

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadPendingDoctorsCount();
    _loadAppointments();
  }

  Future<void> _loadCounts() async {
    final doctorsSnap = await _dbRef.child('doctors').get();
    final patientsSnap = await _dbRef.child('patients').get();
    final hospitalsSnap = await _dbRef.child('hospitals').get();
    final appointmentsSnap = await _dbRef.child('appointments').get();

    if (!mounted) return;

    setState(() {
      totalDoctors = doctorsSnap.value != null
          ? (doctorsSnap.value as Map).length
          : 0;
      totalPatients = patientsSnap.value != null
          ? (patientsSnap.value as Map).length
          : 0;
      totalHospitals = hospitalsSnap.value != null
          ? (hospitalsSnap.value as Map).length
          : 0;
      totalAppointments = appointmentsSnap.value != null
          ? (appointmentsSnap.value as Map).length
          : 0;

      hospitals = hospitalsSnap.value != null
          ? Map<String, dynamic>.from(hospitalsSnap.value as Map)
          : {};
      doctors = doctorsSnap.value != null
          ? Map<String, dynamic>.from(doctorsSnap.value as Map)
          : {};
    });
  }

  Future<void> _loadPendingDoctorsCount() async {
    final snapshot = await _dbRef
        .child('doctors')
        .orderByChild('status')
        .equalTo('pending')
        .get();

    if (!mounted) return;

    setState(() {
      pendingDoctors = snapshot.value != null
          ? (snapshot.value as Map).length
          : 0;
    });
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoadingAppointments = true);
    final snapshot = await _dbRef.child('appointments').get();

    List<Map<String, dynamic>> tmp = [];
    if (snapshot.value != null) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        tmp.add({
          'id': key,
          'doctorName': value['doctorName'] ?? '',
          'patientName': value['patientName'] ?? '',
          'specialty': value['specialization'] ?? '',
          'dateTime': value['dateTime'] ?? '',
          'status': value['status'] ?? 'pending',
          'cancelReason': value['cancelReason'] ?? '',
          'website': value['website'] ?? '',
        });
      });
    }

    if (!mounted) return;
    setState(() {
      appointments = tmp;
      _isLoadingAppointments = false;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      if (!mounted) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open URL")));
    }
  }

  // Send test FCM (keeps http & dart:convert used)
  Future<void> sendTestNotification(String token) async {
    try {
      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=YOUR_SERVER_KEY_HERE",
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": "Test",
            "body": "Hello from AdminDashboard",
          },
        }),
      );
    } catch (e) {
      debugPrint("❌ FCM Error: $e");
    }
  }

  Widget _buildCountCard(String title, int count, Color color) {
    return Card(
      color: color,
      child: SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter and search appointments
    List<Map<String, dynamic>> filteredAppointments = appointments.where((
      appt,
    ) {
      final status = (appt['status'] ?? '').toString().toLowerCase();
      final dt = DateTime.tryParse(appt['dateTime'] ?? '');
      bool matchesFilter = true;

      switch (_selectedFilter) {
        case 1: // Upcoming
          matchesFilter =
              (status == 'pending' || status == 'confirmed') &&
              dt != null &&
              dt.isAfter(DateTime.now());
          break;
        case 2: // Cancelled
          matchesFilter = status == 'cancelled';
          break;
        case 3: // Completed
          matchesFilter = status == 'completed';
          break;
        default:
          matchesFilter = true;
      }

      bool matchesSearch =
          appt['doctorName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          appt['patientName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildCountCard("Doctors", totalDoctors, Colors.blue),
                _buildCountCard("Patients", totalPatients, Colors.green),
                _buildCountCard("Hospitals", totalHospitals, Colors.orange),
                _buildCountCard(
                  "Appointments",
                  totalAppointments,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNavigationCard("Manage Doctors", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDoctorsScreen()),
              );
            }),
            _buildNavigationCard("Manage Patients", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePatientsScreen()),
              );
            }),
            _buildNavigationCard("Manage Hospitals", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageHospitalsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Appointments", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageAppointmentsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Reports", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageReportsScreen()),
              );
            }),
            _buildNavigationCard(
              "Verify Pending Doctors ($pendingDoctors)",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerifyDoctorsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            _isLoadingAppointments
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = filteredAppointments[index];
                      final formattedDate = appt['dateTime'] != ''
                          ? DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(DateTime.parse(appt['dateTime']))
                          : 'N/A';

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${appt['doctorName']} → ${appt['patientName']}",
                          ),
                          subtitle: Text(
                            "${appt['specialty']} | ${appt['status'].toString().toUpperCase()} | $formattedDate",
                          ),
                          trailing: appt['website'] != ''
                              ? IconButton(
                                  icon: const Icon(Icons.link),
                                  onPressed: () => _openUrl(appt['website']),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
