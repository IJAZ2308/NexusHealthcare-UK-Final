import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _selectedFile;
  final TextEditingController _docTitleController = TextEditingController();
  bool _isUploading = false;

  final String cloudName = "dij8c34qm"; // ✅ hardcoded cloud name
  final String uploadPreset = "medi360_unsigned"; // ✅ unsigned preset

  /// Pick file from device
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  /// Upload document to Cloudinary and save metadata to Firebase
  Future<void> _uploadFile() async {
    if (_selectedFile == null || _docTitleController.text.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ Hardcoded Cloudinary upload URL
      final Uri uploadUrl = Uri.parse(
        "https://api.cloudinary.com/v1_1/dij8c34qm/auto/upload", // ✅ hardcoded
      );

      var request = http.MultipartRequest("POST", uploadUrl);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        final String fileUrl = data['secure_url'];

        // Save metadata to Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DatabaseReference dbRef = FirebaseDatabase.instance.ref(
            "doctor_documents/${user.uid}",
          );
          await dbRef.push().set({
            "title": _docTitleController.text,
            "fileUrl": fileUrl,
            "uploadedAt": DateTime.now().toIso8601String(),
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File uploaded successfully!")),
        );

        // Reset fields
        _docTitleController.clear();
        setState(() {
          _selectedFile = null;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Document")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _docTitleController,
              decoration: const InputDecoration(labelText: "Document Title"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text(
                _selectedFile != null ? "File Selected" : "Pick Document",
              ),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadFile,
                    child: const Text("Upload Document"),
                  ),
          ],
        ),
      ),
    );
  }
}
