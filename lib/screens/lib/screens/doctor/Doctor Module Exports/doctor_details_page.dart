import 'package:dr_shahin_uk/screens/lib/screens/doctor/chat/chat_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance.ref(
    'appointments',
  );

  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 30),
            _buildMapButton(),
            const SizedBox(height: 50),
            const Text(
              'Select Date & Time',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildDateTimePicker(),
            const SizedBox(height: 30),
            _buildBookAppointmentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
            color: const Color(0xffF0EFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.doctor.profileImageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.doctor.profileImageUrl,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.doctor.firstName} ${widget.doctor.lastName}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.doctor.category,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'From: ${widget.doctor.city}',
                style: const TextStyle(fontSize: 14, color: Color(0xffFA9600)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/images/phone_call.png',
                      width: 30,
                      height: 30,
                      color: Colors.blue,
                    ),
                    onPressed: () => _makePhoneCall(widget.doctor.phoneNumber),
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/images/chat_icon.png',
                      width: 30,
                      height: 30,
                      color: Colors.blue,
                    ),
                    onPressed: _openChatScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffFFB342),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _openMap,
        child: const Text(
          'VIEW LOCATION ON MAP',
          style: TextStyle(fontSize: 16, letterSpacing: 0.6),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xffF0EFFF),
        border: Border.all(color: const Color(0xffC8C4FF), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0064FA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _selectDate(context),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                    style: const TextStyle(fontSize: 15, letterSpacing: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0064FA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _selectTime(context),
                  child: Text(
                    _selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context),
                    style: const TextStyle(fontSize: 15, letterSpacing: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xffF0EFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookAppointmentButton() {
    return SizedBox(
      width: double.infinity,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0064FA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _bookAppointment,
              child: const Text(
                'BOOK APPOINTMENT',
                style: TextStyle(fontSize: 16, letterSpacing: 2),
              ),
            ),
    );
  }

  // ==================== Functions ====================

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _openMap() async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.doctor.latitude},${widget.doctor.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map')));
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
    }
  }

  void _openChatScreen() {
    final currentUserId = _auth.currentUser!.uid;
    final docName = '${widget.doctor.firstName} ${widget.doctor.lastName}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          doctorId: widget.doctor.uid,
          doctorName: docName,
          patientId: currentUserId,
          patientName: '',
        ),
      ),
    );
  }

  void _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _descriptionController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select a date, time, and add a description for appointment',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);

    final userId = _auth.currentUser!.uid;
    final appointmentId = _appointmentsRef.push().key!;
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final appointmentData = {
      'id': appointmentId,
      'patientId': userId,
      'doctorId': widget.doctor.uid,
      'dateTime': dateTime.toIso8601String(),
      'reason': _descriptionController.text.trim(),
    };

    try {
      await _appointmentsRef.child(appointmentId).set(appointmentData);
      if (!mounted) return;

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _descriptionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully')),
      );

      // Optional: Navigate to PatientAppointmentsScreen automatically
      // Navigator.pushReplacement(context,
      //     MaterialPageRoute(builder: (context) => const PatientAppointmentsScreen()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
