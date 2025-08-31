import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'shared/verify_pending.dart';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  File? _licenseImage;
  String error = '';
  bool loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _licenseImage = File(picked.path));
    }
  }

  Future<String> _uploadLicense(String uid) async {
    final ref =
        FirebaseStorage.instance.ref().child('licenses').child('$uid.jpg');
    await ref.putFile(_licenseImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _registerDoctor() async {
    if (_licenseImage == null) {
      setState(() => error = "Please upload your license.");
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      UserCredential userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final licenseUrl = await _uploadLicense(userCred.user!.uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'uid': userCred.user!.uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': 'doctor',
        'approved': false,
        'licenseUrl': licenseUrl,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyPending()),
      );
    } catch (e) {
      setState(() => error = e.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
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
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
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
}
