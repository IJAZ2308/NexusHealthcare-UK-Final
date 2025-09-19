//lib/services/database_service.dart
import 'package:firebase_database/firebase_database.dart';

/// Models
class HospitalModel {
  final String id;
  final String name;
  final int availableBeds;
  final double latitude;
  final double longitude;
  final String phone;
  final String website;
  final String imageUrl;

  HospitalModel({
    required this.id,
    required this.name,
    required this.availableBeds,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.website,
    required this.imageUrl,
  });

  factory HospitalModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return HospitalModel(
      id: id,
      name: data['name'] ?? '',
      availableBeds: data['availableBeds'] ?? 0,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      phone: data['phone'] ?? '',
      website: data['website'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isVerified;
  final String? specialty;
  final String? hospitalId;
  final HospitalModel? hospital; // linked hospital
  final String? status;
  final List<String>? controlsHospitalIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isVerified,
    this.specialty,
    this.hospitalId,
    this.hospital,
    this.status,
    this.controlsHospitalIds,
  });

  factory UserModel.fromMap(
    String uid,
    Map<dynamic, dynamic> data, {
    HospitalModel? hospital,
  }) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      isVerified: data['isVerified'] ?? false,
      specialty: data['specialty'],
      hospitalId: data['hospitalId'],
      hospital: hospital,
      status: data['status'],
      controlsHospitalIds: (data['controlsHospitalIds'] != null)
          ? List<String>.from(data['controlsHospitalIds'])
          : null,
    );
  }
}

class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String hospitalId;
  final String date;
  final String time;
  final String status;
  final UserModel? doctor; // linked doctor
  final HospitalModel? hospital; // linked hospital

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.hospitalId,
    required this.date,
    required this.time,
    required this.status,
    this.doctor,
    this.hospital,
  });

  factory AppointmentModel.fromMap(
    String id,
    Map<dynamic, dynamic> data, {
    UserModel? doctor,
    HospitalModel? hospital,
  }) {
    return AppointmentModel(
      id: id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      status: data['status'] ?? '',
      doctor: doctor,
      hospital: hospital,
    );
  }
}

class ReportModel {
  final String id;
  final String patientId;
  final String reportName;
  final String reportUrl;
  final String uploadedOn;

  ReportModel({
    required this.id,
    required this.patientId,
    required this.reportName,
    required this.reportUrl,
    required this.uploadedOn,
  });

  factory ReportModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return ReportModel(
      id: id,
      patientId: data['patientId'] ?? '',
      reportName: data['reportName'] ?? '',
      reportUrl: data['reportUrl'] ?? '',
      uploadedOn: data['uploadedOn'] ?? '',
    );
  }
}

/// 🔥 Database Service
class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch all users
  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await _db.child('users').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map(
            (e) =>
                UserModel.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)),
          )
          .toList();
    }
    return [];
  }

  /// Fetch doctors with linked hospital info
  Future<List<UserModel>> fetchDoctorsWithHospital() async {
    final hospitals = await fetchHospitals();
    final hospitalMap = {for (var h in hospitals) h.id: h};

    final users = await fetchUsers();
    final doctors = users.where((u) => u.role == "doctor").toList();

    return doctors.map((doc) {
      final hospital = doc.hospitalId != null
          ? hospitalMap[doc.hospitalId!]
          : null;
      return UserModel.fromMap(doc.uid, {
        'email': doc.email,
        'name': doc.name,
        'role': doc.role,
        'isVerified': doc.isVerified,
        'specialty': doc.specialty,
        'hospitalId': doc.hospitalId,
        'status': doc.status,
        'controlsHospitalIds': doc.controlsHospitalIds,
      }, hospital: hospital);
    }).toList();
  }

  /// Fetch patients
  Future<List<UserModel>> fetchPatients() async {
    final users = await fetchUsers();
    return users.where((u) => u.role == "patient").toList();
  }

  /// Fetch admins
  Future<List<UserModel>> fetchAdmins() async {
    final users = await fetchUsers();
    return users.where((u) => u.role == "admin").toList();
  }

  /// Fetch hospitals
  Future<List<HospitalModel>> fetchHospitals() async {
    final snapshot = await _db.child('hospitals').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map(
            (e) => HospitalModel.fromMap(
              e.key,
              Map<dynamic, dynamic>.from(e.value),
            ),
          )
          .toList();
    }
    return [];
  }

  /// Fetch appointments with linked doctor & hospital
  Future<List<AppointmentModel>> fetchAppointments() async {
    final hospitals = await fetchHospitals();
    final hospitalMap = {for (var h in hospitals) h.id: h};

    final doctors = await fetchDoctorsWithHospital();
    final doctorMap = {for (var d in doctors) d.uid: d};

    final snapshot = await _db.child('appointments').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((e) {
        final map = Map<dynamic, dynamic>.from(e.value);
        final doc = doctorMap[map['doctorId']];
        final hosp = map['hospitalId'] != null
            ? hospitalMap[map['hospitalId']]
            : null;
        return AppointmentModel.fromMap(
          e.key,
          map,
          doctor: doc,
          hospital: hosp,
        );
      }).toList();
    }
    return [];
  }

  /// Fetch reports
  Future<List<ReportModel>> fetchReports() async {
    final snapshot = await _db.child('reports').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map(
            (e) =>
                ReportModel.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)),
          )
          .toList();
    }
    return [];
  }
}

/// ✅ Usage Example
/*
final dbService = DatabaseService();

Future<void> loadDoctorsWithHospitals() async {
  List<UserModel> doctors = await dbService.fetchDoctorsWithHospital();
  for (var doc in doctors) {
    print("Doctor: ${doc.name}, Specialty: ${doc.specialty}, Hospital: ${doc.hospital?.name ?? 'N/A'}");
  }
}

Future<void> loadAppointments() async {
  List<AppointmentModel> appointments = await dbService.fetchAppointments();
  for (var appt in appointments) {
    print("Appointment with ${appt.doctor?.name ?? 'Unknown'} at ${appt.hospital?.name ?? 'Unknown'} on ${appt.date} ${appt.time}");
  }
}
*/
