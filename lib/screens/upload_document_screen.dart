import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class UploadDocumentScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const UploadDocumentScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required String doctorId,
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _selectedFile;
  final TextEditingController _docTitleController = TextEditingController();
  bool _isUploading = false;

  final String cloudName = "dij8c34qm"; // Cloudinary cloud name
  final String uploadPreset = "medi360_unsigned"; // Unsigned preset

  /// Pick file from device
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  /// Upload document to Cloudinary and Firebase
  Future<void> _uploadFile() async {
    if (_selectedFile == null || _docTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file and enter a title")),
      );
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in!")));
      return;
    }
    final String doctorId = currentUser.uid;

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dij8c34qm/auto/upload",
      );
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedFile!.path,
            filename: path.basename(_selectedFile!.path),
            contentType: MediaType('application', 'octet-stream'),
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fileUrl = data['secure_url'];

        // Save to Firebase
        final metadata = {
          "title": _docTitleController.text,
          "fileUrl": fileUrl,
          "uploadedAt": DateTime.now().toIso8601String(),
          "patientName": widget.patientName,
          "doctorId": doctorId,
        };

        // For doctor
        final doctorRef = FirebaseDatabase.instance.ref(
          "doctor_documents/$doctorId/${widget.patientId}",
        );
        await doctorRef.push().set(metadata);

        // For patient
        final patientRef = FirebaseDatabase.instance.ref(
          "patient_documents/${widget.patientId}/$doctorId",
        );
        await patientRef.push().set(metadata);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File uploaded successfully!")),
        );

        _docTitleController.clear();
        setState(() {
          _selectedFile = null;
          _isUploading = false;
        });
      } else {
        throw Exception("Cloudinary upload failed: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Document for ${widget.patientName}"),
        backgroundColor: const Color(0xff0064FA),
      ),
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
