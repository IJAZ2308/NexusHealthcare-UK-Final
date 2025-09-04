import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  UploadDocumentScreenState createState() => UploadDocumentScreenState();
}

class UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? selectedFile;
  final TextEditingController docTitleController = TextEditingController();
  bool uploading = false;

  // Initialize Cloudinary
  final cloudinary = Cloudinary.full(
    apiKey: '755248332976533CgcnvLlza96bFvfGcx1CamvLDQ4',
    apiSecret: 'CgcnvLlza96bFvfGcx1CamvLDQ4',
    cloudName: 'dij8c34qm',
  );

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
      // Upload to Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: selectedFile!.path,
          resourceType: CloudinaryResourceType.auto,
          folder: "documents/$uid",
        ),
      );

      if (response.isSuccessful) {
        final url = response.secureUrl;

        // Save metadata to Realtime Database
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

    if (mounted) setState(() => uploading = false);
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
