import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/verify_pending.dart';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key});

  @override
  RegisterDoctorScreenState createState() => RegisterDoctorScreenState();
}

class RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  File? _licenseImage;
  String error = '';
  bool loading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _licenseImage = File(picked.path));
    }
  }

  Future<String> uploadLicense(String uid) async {
    final ref =
        FirebaseStorage.instance.ref().child('licenses').child('$uid.jpg');
    await ref.putFile(_licenseImage!);
    return await ref.getDownloadURL();
  }

  void registerDoctor() async {
    if (_licenseImage == null) {
      setState(() => error = "Upload your license to register.");
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

      final licenseUrl = await uploadLicense(userCred.user!.uid);

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
      setState(() {
        error = e.toString();
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
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
            children: [
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _licenseImage != null
                  ? Image.file(_licenseImage!, height: 100)
                  : const Text("No License Uploaded"),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Upload License"),
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: registerDoctor,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
