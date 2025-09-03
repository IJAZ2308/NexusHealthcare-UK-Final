// lib/services/auth_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Cloudinary details
  final String cloudName = "dij8c34qm";
  final String uploadPreset = "medi360_unsigned";

  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    File? licenseFile,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? licenseUrl;

      if (role == 'doctor' && licenseFile != null) {
        final uploadUrl = Uri.parse(
          "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
        );

        final request = http.MultipartRequest("POST", uploadUrl)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath('file', licenseFile.path),
          );

        final response = await request.send();
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);

        if (response.statusCode == 200 && data['secure_url'] != null) {
          licenseUrl = data['secure_url'];
        } else {
          throw Exception("Cloudinary upload failed: ${data['error']}");
        }
      }

      // Save user in Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'isVerified': role == 'doctor' ? false : true,
        'licenseUrl': licenseUrl ?? '',
      });

      return true;
    } catch (e) {
      developer.log("Register error", error: e);
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _db.collection('users').doc(result.user!.uid).get();
      final data = doc.data();

      if (data == null) return null;

      if (data['role'] == 'doctor' && data['isVerified'] == false) {
        return null; // Doctor must be verified by admin
      }

      return data['role'];
    } catch (e) {
      developer.log("Login error", error: e);
      return null;
    }
  }
}
