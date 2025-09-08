// lib/screens/register_doctor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dr_shahin_uk/main.dart'; // AuthService
import 'package:dr_shahin_uk/screens/shared/verify_pending.dart';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  File? _licenseImage;
  String error = '';
  bool loading = false;

  /// Pick license image from gallery
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _licenseImage = File(picked.path));
      }
    } catch (e) {
      setState(() => error = 'Failed to pick image: $e');
    }
  }

  /// Register doctor with Firebase Auth + RTDB + Cloudinary
  Future<void> _registerDoctor() async {
    if (_licenseImage == null) {
      setState(() => error = "Please upload your license.");
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    // Call AuthService.registerUser
    final bool success = await _authService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      role: 'doctor',
      licenseFile: _licenseImage,
    );

    if (!mounted) return;

    if (success) {
      // ✅ Registration success → show pending verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyPending()),
      );
    } else {
      // ❌ Registration failed → show error
      setState(() => error = 'Registration failed. Please try again.');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register as Doctor")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _licenseImage != null
                  ? Image.file(_licenseImage!, height: 120)
                  : const Text("No license uploaded"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Upload License"),
              ),
              const SizedBox(height: 20),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerDoctor,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
