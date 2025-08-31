import 'package:dr_shahin_uk/screens/auth/login_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _requestDatabase =
      FirebaseDatabase.instance.ref().child('Requests');

  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  /// Fetch bookings for the current user
  Future<void> _fetchBookings() async {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final event = await _requestDatabase
          .orderByChild('sender')
          .equalTo(currentUserId)
          .once();

      if (event.snapshot.value != null) {
        final bookingMap = event.snapshot.value as Map<dynamic, dynamic>;
        final tempBookings = bookingMap.entries.map((entry) {
          return Booking.fromMap(Map<String, String>.from(entry.value), id: '');
        }).toList();

        setState(() {
          _bookings = tempBookings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching bookings: $e");
    }
  }

  /// Logout and navigate to LoginPage
  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Widget for empty state
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No bookings available',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  /// Widget for booking list
  Widget _buildBookingList() {
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(booking.description),
            subtitle: Text("Date: ${booking.date}  |  Time: ${booking.time}"),
            trailing: Text(
              booking.status,
              style: TextStyle(
                color: booking.status.toLowerCase() == "approved"
                    ? Colors.green
                    : (booking.status.toLowerCase() == "pending"
                        ? Colors.orange
                        : Colors.red),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState()
              : _buildBookingList(),
    );
  }
}
