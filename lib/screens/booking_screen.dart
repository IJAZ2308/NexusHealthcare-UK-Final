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
  List<Map<String, dynamic>> doctorsList = [];
  String? selectedDoctor;

  @override
  void initState() {
    super.initState();
    // Save to "appointments" for doctor dashboard
    _dbRef = FirebaseDatabase.instance.ref().child('appointments');
    _fetchDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    final doctorRef = FirebaseDatabase.instance.ref().child('doctors');
    final snapshot = await doctorRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> tempList = [];
      data.forEach((key, value) {
        Map<String, dynamic> doctor = Map<String, dynamic>.from(value);
        doctor['id'] = key;

        // Optional: Only include doctors for this hospital
        if (doctor['hospitalId'] == widget.hospital['id']) {
          tempList.add(doctor);
        }
      });
      setState(() {
        doctorsList = tempList;
        if (doctorsList.isNotEmpty) selectedDoctor = doctorsList[0]['name'];
      });
    }
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
        _selectedTime == null ||
        selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final hospital = widget.hospital;
    final hospitalName = hospital['name'] ?? "Unknown Hospital";

    // Find doctor ID
    final doctorData = doctorsList.firstWhere(
      (doc) => doc['name'] == selectedDoctor,
      orElse: () => {},
    );
    final doctorName = doctorData['name'] ?? "Unknown Doctor";
    final doctorId = doctorData['id'] ?? "unknown";

    final bookingData = {
      "patientName": _nameController.text,
      "hospital": hospitalName,
      "doctor": doctorName,
      "doctorId": doctorId,
      "date": _selectedDate!.toIso8601String(),
      "time": _selectedTime!.format(context),
      "notes": _noteController.text,
      "createdAt": DateTime.now().toIso8601String(),
    };

    setState(() {
      _isLoading = true;
    });

    try {
      await _dbRef.push().set(bookingData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
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

              // Doctor Dropdown
              doctorsList.isEmpty
                  ? const Text("Loading doctors...")
                  : DropdownButtonFormField<String>(
                      value: selectedDoctor,
                      items: doctorsList.map((doctor) {
                        return DropdownMenuItem<String>(
                          value: doctor['name'],
                          child: Text(doctor['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDoctor = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Doctor',
                        border: OutlineInputBorder(),
                      ),
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
