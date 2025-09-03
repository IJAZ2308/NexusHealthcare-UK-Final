import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  UploadDocumentScreenState createState() => UploadDocumentScreenState();
}

class UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _selectedFile;
  final TextEditingController _docTitleController = TextEditingController();
  bool _uploading = false;

  // ✅ Initialize Cloudinary
  final cloudinary = Cloudinary.full(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET", // ⚠️ use unsigned preset in production
    cloudName: "YOUR_CLOUD_NAME",
  );

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _docTitleController.text.isEmpty) return;

    setState(() => _uploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // ✅ Upload to Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _selectedFile!.path,
          resourceType: CloudinaryResourceType.auto,
          folder: "documents/$uid", // organize by user
        ),
      );

      if (response.isSuccessful) {
        final url = response.secureUrl;

        // ✅ Save Cloudinary URL in Firestore
        await FirebaseFirestore.instance.collection('documents').add({
          'userId': uid,
          'title': _docTitleController.text,
          'url': url,
          'uploadedAt': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded to Cloudinary')),
        );

        _docTitleController.clear();
        setState(() {
          _selectedFile = null;
        });
      } else {
        developer.log("Cloudinary upload failed: ${response.error}");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    } catch (e) {
      developer.log('Upload error', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }

    if (mounted) {
      setState(() => _uploading = false);
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
              controller: _docTitleController,
              decoration: const InputDecoration(labelText: 'Document Title'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text(
                _selectedFile != null ? 'File Selected' : 'Pick Document',
              ),
            ),
            const SizedBox(height: 20),
            _uploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadFile,
                    child: const Text('Upload Document'),
                  ),
          ],
        ),
      ),
    );
  }
}
