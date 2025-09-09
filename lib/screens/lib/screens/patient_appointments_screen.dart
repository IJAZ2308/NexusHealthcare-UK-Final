import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialization;

  const BookAppointmentScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _loading = false;

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final dbRef = FirebaseDatabase.instance.ref().child("appointments");

    final newAppointmentRef = dbRef.push();

    await newAppointmentRef.set({
      "patientId": uid,
      "doctorId": widget.doctorId,
      "doctorName": widget.doctorName,
      "specialization": widget.specialization,
      "date": _dateController.text,
      "time": _timeController.text,
      "reason": _reasonController.text,
      "status": "pending",
    });

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book with ${widget.doctorName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Specialization: ${widget.specialization}"),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                ),
                validator: (value) => value!.isEmpty ? "Enter a date" : null,
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: "Time (e.g., 10:30 AM)",
                ),
                validator: (value) => value!.isEmpty ? "Enter a time" : null,
              ),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason for visit",
                ),
                validator: (value) => value!.isEmpty ? "Enter a reason" : null,
              ),

              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _bookAppointment,
                      child: const Text("Book Appointment"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
