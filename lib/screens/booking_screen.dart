import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> hospital; // store hospital info

  const BookingScreen({super.key, required this.hospital});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  late DatabaseReference _dbRef;

  @override
  void initState() {
    super.initState();
    // Save to "appointments" for doctor dashboard
    _dbRef = FirebaseDatabase.instance.ref().child('appointments');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveBooking() async {
    if (_nameController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final hospital = widget.hospital;
    final hospitalName = hospital['name'] ?? "Unknown Hospital";
    final doctorName = hospital['doctor'] ?? "Unknown Doctor";
    final doctorId = hospital['doctorId'] ?? "unknown";

    final bookingData = {
      "patientName": _nameController.text,
      "hospital": hospitalName,
      "doctor": doctorName,
      "doctorId": doctorId, // crucial for doctor dashboard
      "date": _selectedDate!.toIso8601String(),
      "time": _selectedTime!.format(context),
      "notes": _noteController.text,
      "createdAt": DateTime.now().toIso8601String(),
    };

    setState(() {
      _isLoading = true;
    });

    try {
      // Push creates a unique key for each appointment
      await _dbRef.push().set(bookingData);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving appointment: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospital = widget.hospital;
    final hospitalName = hospital['name'] ?? "Unknown Hospital";
    final doctorName = hospital['doctor'] ?? "Unknown Doctor";

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hospital: $hospitalName",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Doctor: $doctorName",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickDate,
                      child: Text(
                        _selectedDate == null
                            ? "Select Date"
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickTime,
                      child: Text(
                        _selectedTime == null
                            ? "Select Time"
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveBooking,
                        child: const Text("Save Appointment"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
