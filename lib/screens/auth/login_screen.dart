// lib/screens/login_screen.dart

import 'package:dr_shahin_uk/screens/auth/register_selection.dart';
import 'package:dr_shahin_uk/screens/lib/screens/admin_dashboard.dart';
import 'package:dr_shahin_uk/screens/lib/screens/doctor_dashboard.dart';
import 'package:dr_shahin_uk/screens/lib/screens/patient_dashboard.dart';
import 'package:dr_shahin_uk/screens/shared/verify_pending.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  bool _isLoading = false;
  bool _obscureText = true;
  String error = "";

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      error = "";
    });

    try {
      // 1️⃣ Sign in user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        setState(() => error = "Login failed. UID not found.");
        return;
      }

      // 2️⃣ Get user data from Realtime Database
      final snapshot = await _db.child("users").child(uid).get();

      if (!snapshot.exists) {
        setState(() => error = "User not found in database.");
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      String role = data['role'] ?? '';
      bool verified = data['isVerified'] ?? true;

      if (!mounted) return;

      // 3️⃣ Navigate based on role & verification
      if (role == 'doctor' && !verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyPending()),
        );
      } else if (role == 'doctor' && verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
        );
      } else if (role == 'patient') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        setState(() => error = 'Unknown role. Contact admin.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Login failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Image.asset('assets/images/plus.png'),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Login first',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (error.isNotEmpty)
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),

                        // Email Field
                        SizedBox(
                          height: 50,
                          child: TextFormField(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xffF0EFFF),
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (val) => email = val,
                            validator: (val) =>
                                val!.isEmpty ? 'Enter an email' : null,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Password Field
                        SizedBox(
                          height: 50,
                          child: TextFormField(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xffF0EFFF),
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureText,
                            onChanged: (val) => password = val,
                            validator: (val) => val!.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0064FA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register Link
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterSelectionScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Don’t have an account? Register',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
