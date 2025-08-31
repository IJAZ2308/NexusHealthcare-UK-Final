import 'package:dr_shahin_uk/screens/lib/screens/doctor/chat/chat_screen.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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
  final DatabaseReference _requestDatabase =
      FirebaseDatabase.instance.ref('Requests');

  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
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
                              fit: BoxFit.fitWidth,
                            ),
                          )
                        : const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Column(
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
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${widget.doctor.city}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffFA9600),
                        ),
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
                            onPressed: () =>
                                _makePhoneCall(widget.doctor.phoneNumber),
                          ),
                          IconButton(
                            icon: Image.asset(
                              'assets/images/chat_icon.png',
                              width: 30,
                              height: 30,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              String currentUserId = _auth.currentUser!.uid;
                              String docName =
                                  '${widget.doctor.firstName} ${widget.doctor.lastName}';
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
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFFB342),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
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
              ),

              const SizedBox(height: 50),
              const Text(
                'Select Date & Time',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xffF0EFFF),
                  border: Border.all(
                    color: Color(0xffC8C4FF),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  : DateFormat('MM/dd/yyyy')
                                      .format(_selectedDate!),
                              style: const TextStyle(
                                  fontSize: 15, letterSpacing: 0.6),
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
                              style: const TextStyle(
                                  fontSize: 15, letterSpacing: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
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
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0064FA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  // Select time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && picked != _selectedTime && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  // Open Google Maps
  void _openMap() async {
    final Uri googleMapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.doctor.latitude},${widget.doctor.longitude}',
    );
    if (await canLaunchUrl(googleMapUri)) {
      await launchUrl(googleMapUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  // Phone call
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $phoneNumber')),
      );
    }
  }

  // Book appointment
  void _bookAppointment() {
    if (_selectedDate != null &&
        _selectedTime != null &&
        _descriptionController.text.isNotEmpty) {
      String date = DateFormat('MM/dd/yyyy').format(_selectedDate!);
      String time = _selectedTime!.format(context);
      String description = _descriptionController.text;
      String requestId = _requestDatabase.push().key!;
      String currentUserId = _auth.currentUser!.uid;
      String receiverId = widget.doctor.uid;
      String status = 'pending';

      _requestDatabase.child(requestId).set({
        'date': date,
        'time': time,
        'description': description,
        'id': requestId,
        'receiver': receiverId,
        'sender': currentUserId,
        'status': status,
      }).then((_) {
        if (!mounted) return;
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _descriptionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
      }).catchError((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book your appointment, Try Again later!!'),
          ),
        );
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Select a date and time also add a description for appointment')),
      );
    }
  }
}
