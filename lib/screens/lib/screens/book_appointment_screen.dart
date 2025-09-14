import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
  final _reasonController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final appointmentRef = FirebaseDatabase.instance
          .ref()
          .child("appointments")
          .push();

      final appointmentId = appointmentRef.key;

      await appointmentRef.set({
        "id": appointmentId,
        "patientId": user.uid,
        "doctorId": widget.doctorId,
        "doctorName": widget.doctorName,
        "specialization": widget.specialization,
        "reason": _reasonController.text.trim(),
        "dateTime": _selectedDateTime!.toIso8601String(),
        "status": "pending", // 🔥 added default status
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment booked successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: "Reason"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a reason" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? "No date selected"
                          : DateFormat(
                              "yyyy-MM-dd HH:mm",
                            ).format(_selectedDateTime!),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickDateTime,
                    child: const Text("Pick Date & Time"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
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
