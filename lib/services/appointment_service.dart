import 'package:dr_shahin_uk/screens/lib/screens/models/appointment_model.dart';
import 'package:firebase_database/firebase_database.dart';

class AppointmentService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "appointments",
  );

  /// Add a new appointment
  Future<void> addAppointment(Appointment appointment) async {
    final newRef = _dbRef.push();
    await newRef.set(appointment.toMap());
  }

  /// Get all appointments (stream for real-time updates)
  Stream<List<Appointment>> getAppointments() {
    return _dbRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      return data.entries.map((e) {
        return Appointment.fromMap(e.key, e.value);
      }).toList();
    });
  }
}
