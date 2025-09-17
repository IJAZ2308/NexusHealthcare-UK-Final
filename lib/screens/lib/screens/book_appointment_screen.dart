import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/doctor.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  List<DateTime> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  Future<void> _fetchBookedSlots() async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('appointments')
        .orderByChild('doctorId')
        .equalTo(widget.doctor.uid)
        .get();

    List<DateTime> slots = [];
    if (snapshot.exists) {
      Map<dynamic, dynamic> appointments =
          snapshot.value as Map<dynamic, dynamic>;
      appointments.forEach((key, value) {
        if (value['dateTime'] != null) {
          slots.add(DateTime.parse(value['dateTime']));
        }
      });
    }

    if (!mounted) return;
    setState(() {
      _bookedSlots = slots;
    });
  }

  Future<void> _pickDateTime() async {
    // Pick date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (day) {
        if (day.isBefore(DateTime.now())) return false;

        int bookedCount = _bookedSlots
            .where(
              (slot) =>
                  slot.year == day.year &&
                  slot.month == day.month &&
                  slot.day == day.day,
            )
            .length;
        return bookedCount < 24; // assuming max 24 slots/day
      },
    );

    if (pickedDate == null || !mounted) return;

    // Pick time
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    bool isBooked = _bookedSlots.any(
      (slot) =>
          slot.year == finalDateTime.year &&
          slot.month == finalDateTime.month &&
          slot.day == finalDateTime.day &&
          slot.hour == finalDateTime.hour &&
          slot.minute == finalDateTime.minute,
    );

    if (isBooked || finalDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This slot is already booked!")),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedDateTime = finalDateTime;
    });
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
        "doctorId": widget.doctor.uid,
        "doctorName": "${widget.doctor.firstName} ${widget.doctor.lastName}",
        "specialization": widget.doctor.category,
        "reason": _reasonController.text.trim(),
        "dateTime": _selectedDateTime!.toIso8601String(),
        "status": "pending",
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked successfully!")),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Doctor Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(doctor.profileImageUrl),
                    radius: 25,
                  ),
                  title: Text("${doctor.firstName} ${doctor.lastName}"),
                  subtitle: Text(
                    "${doctor.category} • ${doctor.qualification}",
                  ),
                  trailing: doctor.isVerified
                      ? const Icon(Icons.verified, color: Colors.green)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason for Appointment",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a reason" : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Date & Time Picker
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

              // Book Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
