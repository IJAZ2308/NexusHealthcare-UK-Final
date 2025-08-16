import 'package:flutter/material.dart';
import 'upload_document_screen.dart';
import 'view_documents_screen.dart';

class DocumentDashboardScreen extends StatelessWidget {
  const DocumentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Documents")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text("Upload Document"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UploadDocumentScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("View Documents"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ViewDocumentsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
