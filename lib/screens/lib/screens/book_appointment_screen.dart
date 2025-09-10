import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/appointment_model.dart';

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
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _loading = false;

  /// Pick date & time
  Future<void> _pickDateTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (selectedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String get _formattedDateTime {
    if (_selectedDateTime == null) return 'Tap to select';
    return DateFormat('EEE, dd MMM yyyy – hh:mm a').format(_selectedDateTime!);
  }

  /// Book appointment in Firebase
  Future<void> _bookAppointment() async {
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date & time")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final dbRef = FirebaseDatabase.instance.ref().child("appointments");

      // Check for double booking
      final snapshot = await dbRef
          .orderByChild('doctorId')
          .equalTo(widget.doctorId)
          .get();
      bool conflict = false;
      if (snapshot.exists) {
        final appointments = snapshot.value as Map<dynamic, dynamic>;
        for (var appt in appointments.values) {
          final existingDate = DateTime.parse(appt['dateTime']);
          if (existingDate == _selectedDateTime) {
            conflict = true;
            break;
          }
        }
      }

      if (conflict) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This time slot is already booked!")),
        );
        return;
      }

      // Book appointment
      final newAppointmentRef = dbRef.push();
      final appointmentData = Appointment(
        id: newAppointmentRef.key!,
        patientId: user.uid,
        doctorId: widget.doctorId,
        dateTime: _selectedDateTime!,
        reason: _reasonController.text.trim(),
      ).toMap();

      await newAppointmentRef.set(appointmentData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error booking appointment: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book with ${widget.doctorName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Specialization: ${widget.specialization}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Date & Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formattedDateTime),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reason for visit",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a reason" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _bookAppointment,
                        child: const Text("Book Appointment"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
