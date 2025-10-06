import 'package:dr_shahin_uk/screens/lib/screens/verify_doctors_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for logout
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ Added

  int totalDoctors = 0;
  int consultingDoctors = 0;
  int labDoctors = 0;
  int pendingDoctors = 0;
  int totalPatients = 0;
  int totalHospitals = 0;
  int totalAppointments = 0;

  Map<String, dynamic> hospitals = {};
  List<Map<String, dynamic>> appointments = [];

  bool _isLoadingAppointments = true;
  final int _selectedFilter = 0; // 0=All, 1=Upcoming, 2=Cancelled, 3=Completed
  final String _searchQuery = "";
  String _doctorFilter = "all"; // all | consulting | lab

  // NEW: Realtime pending doctors
  StreamSubscription<DatabaseEvent>? _pendingDoctorsSubscription;
  final List<String> _pendingDoctorUids = [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadAppointments();
    _listenPendingDoctors();
  }

  @override
  void dispose() {
    _pendingDoctorsSubscription?.cancel();
    super.dispose();
  }

  // ✅ Logout Function
  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadCounts() async {
    final usersSnap = await _dbRef.child('users').get();
    final hospitalsSnap = await _dbRef.child('hospitals').get();
    final appointmentsSnap = await _dbRef.child('appointments').get();

    int docCount = 0;
    int patientCount = 0;
    int consultingCount = 0;
    int labCount = 0;
    int pendingCount = 0;

    if (usersSnap.value != null) {
      final map = Map<String, dynamic>.from(usersSnap.value as Map);
      map.forEach((key, value) {
        final user = Map<String, dynamic>.from(value);
        final role = user['role'] ?? '';
        final status = user['status'] ?? '';
        final category = (user['category'] ?? '').toString().toLowerCase();

        if (role == 'patient') {
          patientCount++;
        } else if (role == 'doctor') {
          docCount++;
          if (status == 'pending') pendingCount++;
          if (category.contains('consult')) consultingCount++;
          if (category.contains('lab')) labCount++;
        }
      });
    }

    setState(() {
      totalDoctors = docCount;
      totalPatients = patientCount;
      consultingDoctors = consultingCount;
      labDoctors = labCount;
      pendingDoctors = pendingCount;
      totalHospitals = hospitalsSnap.value != null
          ? (hospitalsSnap.value as Map).length
          : 0;
      totalAppointments = appointmentsSnap.value != null
          ? (appointmentsSnap.value as Map).length
          : 0;
      hospitals = hospitalsSnap.value != null
          ? Map<String, dynamic>.from(hospitalsSnap.value as Map)
          : {};
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open URL")));
    }
  }

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

  Widget _buildNavigationCard(
    String title,
    int badgeCount,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text(title),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  void _showDoctorFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Filter Doctors"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("All"),
              onTap: () {
                setState(() => _doctorFilter = "all");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("Consulting Doctors"),
              onTap: () {
                setState(() => _doctorFilter = "consulting");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("Lab Doctors"),
              onTap: () {
                setState(() => _doctorFilter = "lab");
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _listenPendingDoctors() {
    _pendingDoctorsSubscription = _dbRef
        .child('users')
        .orderByChild('status')
        .equalTo('pending')
        .onChildAdded
        .listen((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            final doctorName = data['name'] ?? 'New Doctor';
            final doctorUid = event.snapshot.key!;
            if (!_pendingDoctorUids.contains(doctorUid)) {
              _pendingDoctorUids.add(doctorUid);
              _showNewDoctorPopup(doctorName);
              _loadCounts();
            }
          }
        });
  }

  void _showNewDoctorPopup(String doctorName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Doctor Registration"),
        content: Text(
          "$doctorName has registered and is pending verification.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerifyPending()),
              );
            },
            child: const Text("Verify Now"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredAppointments = appointments.where((
      appt,
    ) {
      final status = (appt['status'] ?? '').toString().toLowerCase();
      final dt = DateTime.tryParse(appt['dateTime'] ?? '');
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 1:
          matchesFilter =
              (status == 'pending' || status == 'confirmed') &&
              dt != null &&
              dt.isAfter(DateTime.now());
          break;
        case 2:
          matchesFilter = status == 'cancelled';
          break;
        case 3:
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
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // ✅ Logout Button Added
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDoctorFilterDialog,
          ),
        ],
      ),
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
                if (_doctorFilter == "all" || _doctorFilter == "consulting")
                  _buildCountCard(
                    "Consulting Doctors",
                    consultingDoctors,
                    Colors.blue,
                  ),
                if (_doctorFilter == "all" || _doctorFilter == "lab")
                  _buildCountCard("Lab Doctors", labDoctors, Colors.purple),
                if (_doctorFilter == "all")
                  _buildCountCard("Doctors", totalDoctors, Colors.teal),
                _buildCountCard("Patients", totalPatients, Colors.green),
                _buildCountCard("Hospitals", totalHospitals, Colors.orange),
                _buildCountCard("Appointments", totalAppointments, Colors.pink),
                _buildCountCard("Pending Doctors", pendingDoctors, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            _buildNavigationCard("Manage Doctors", 0, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDoctorsScreen()),
              );
            }),
            _buildNavigationCard("Manage Patients", 0, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePatientsScreen()),
              );
            }),
            _buildNavigationCard("Manage Hospitals", 0, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageHospitalsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Appointments", 0, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageAppointmentsScreen(),
                ),
              );
            }),
            _buildNavigationCard("Manage Reports", 0, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageReportsScreen()),
              );
            }),
            _buildNavigationCard("Verify Pending Doctors", pendingDoctors, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerifyPending()),
              );
            }),
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
