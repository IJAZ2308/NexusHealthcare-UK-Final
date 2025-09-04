import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  UploadDocumentScreenState createState() => UploadDocumentScreenState();
}

class UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? selectedFile;
  final TextEditingController docTitleController = TextEditingController();
  bool uploading = false;

  // Cloudinary credentials
  final String cloudName = "dij8c34qm"; // Your Cloudinary Cloud Name
  final String uploadPreset = "medi360_unsigned"; // Your Unsigned Upload Preset

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null || docTitleController.text.isEmpty) return;

    setState(() => uploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final DatabaseReference documentsRef = FirebaseDatabase.instance
        .ref()
        .child('documents');

    try {
      // Upload file to Cloudinary
      final uploadUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
      );
      final request = http.MultipartRequest("POST", uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath('file', selectedFile!.path),
        );

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);

      if (response.statusCode != 200 || data['secure_url'] == null) {
        throw Exception("Cloudinary upload failed: ${data['error']}");
      }

      final url = data['secure_url'];

      // Save metadata in Realtime Database
      await documentsRef.push().set({
        'userId': uid,
        'title': docTitleController.text,
        'url': url,
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully')),
      );
      docTitleController.clear();
      setState(() {
        selectedFile = null;
      });
    } catch (e) {
      developer.log('Upload error', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }

    if (mounted) {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: docTitleController,
              decoration: const InputDecoration(labelText: 'Document Title'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickFile,
              child: Text(
                selectedFile != null ? 'File Selected' : 'Pick Document',
              ),
            ),
            const SizedBox(height: 20),
            uploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: uploadFile,
                    child: const Text('Upload Document'),
                  ),
          ],
        ),
      ),
    );
  }
}
