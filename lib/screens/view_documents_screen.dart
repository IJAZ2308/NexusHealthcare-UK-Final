import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewDocumentsScreen extends StatelessWidget {
  const ViewDocumentsScreen({
    super.key,
    required String patientId,
    required String patientName,
    required String doctorName,
    required String doctorId,
  });

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DatabaseReference documentsRef = FirebaseDatabase.instance
        .ref()
        .child('documents');

    return Scaffold(
      appBar: AppBar(title: const Text("My Documents")),
      body: StreamBuilder<DatabaseEvent>(
        stream: documentsRef.orderByChild('userId').equalTo(uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No documents found."));
          }

          final Map<dynamic, dynamic> documentsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Convert to list and sort by uploadedAt descending
          final List<Map<dynamic, dynamic>> documents =
              documentsMap.entries.map((entry) {
                final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                  entry.value,
                );
                data['id'] = entry.key;
                return data;
              }).toList()..sort(
                (a, b) =>
                    (b['uploadedAt'] ?? 0).compareTo(a['uploadedAt'] ?? 0),
              );

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index];

              return ListTile(
                title: Text(data['title'] ?? 'Untitled'),
                subtitle: Text(
                  "Uploaded on: ${DateTime.fromMillisecondsSinceEpoch(data['uploadedAt'] ?? 0)}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final Uri url = Uri.parse(data['url'] ?? '');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
