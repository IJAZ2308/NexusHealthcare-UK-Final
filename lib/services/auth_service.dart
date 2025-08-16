// lib/services/auth_service.dart

import 'dart:io';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    File? licenseFile,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      String? licenseUrl;
      if (role == 'doctor' && licenseFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('licenses')
            .child("${result.user!.uid}.jpg");
        await ref.putFile(licenseFile);
        licenseUrl = await ref.getDownloadURL();
      }

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
          email: email, password: password);

      final doc = await _db.collection('users').doc(result.user!.uid).get();
      final data = doc.data();

      if (data == null) return null;

      if (data['role'] == 'doctor' && data['isVerified'] == false) {
        return null;
      }

      return data['role'];
    } catch (e) {
      developer.log("Login error", error: e);
      return null;
    }
  }
}
