import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BedBookingScreen extends StatefulWidget {
  final Map<String, dynamic> hospital; // hospital details from hospital list

  const BedBookingScreen({super.key, required this.hospital});

  @override
  State<BedBookingScreen> createState() => _BedBookingScreenState();
}

class _BedBookingScreenState extends State<BedBookingScreen> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? selectedBedType;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> bedTypes = [
    "General Ward",
    "Semi-Private Room",
    "Private Room",
    "ICU",
  ];

  late DatabaseReference _dbRef;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref().child("bedBookings");
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
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

  Future<void> _saveBooking() async {
    if (_patientNameController.text.isEmpty ||
        _selectedDate == null ||
        selectedBedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final hospital = widget.hospital;
    final hospitalName = hospital['name'] ?? "Unknown Hospital";
    final hospitalId = hospital['id'] ?? "unknown_hospital";

    final bookingData = {
      "patientUid": _currentUser?.uid ?? "anonymous",
      "patientName": _patientNameController.text,
      "hospitalId": hospitalId,
      "hospital": hospitalName,
      "bedType": selectedBedType,
      "bookingDate": _selectedDate!.toIso8601String(),
      "notes": _notesController.text,
      "status": "Pending", // Admin can approve/reject later
      "createdAt": DateTime.now().toIso8601String(),
    };

    try {
      await _dbRef.push().set(bookingData);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bed booking request sent successfully!")),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving booking: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalName = widget.hospital['name'] ?? "Unknown Hospital";

    return Scaffold(
      appBar: AppBar(title: const Text("Book a Bed")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hospital: $hospitalName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Bed Type Selection
              DropdownButtonFormField<String>(
                value: selectedBedType,
                items: bedTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBedType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Select Bed Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Patient Name
              TextField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: "Patient Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(
                  _selectedDate == null
                      ? "Select Admission Date"
                      : "Selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Additional Notes (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.local_hotel),
                        label: const Text("Book Bed"),
                        onPressed: _saveBooking,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
