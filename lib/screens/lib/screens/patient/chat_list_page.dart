import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key}); // ✅ use super.key

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    // ✅ Instead of unused variables, directly use them inside StreamBuilder
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text("No chats available"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final List participants =
                  chat['participants'] ?? []; // user + doctor

              // Get doctor reference (avoids unused variable)
              final String doctorId =
                  participants.firstWhere((id) => id != user.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('doctors').doc(doctorId).get(),
                builder: (context, doctorSnapshot) {
                  if (!doctorSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final doctorData =
                      doctorSnapshot.data?.data() as Map<String, dynamic>?;

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(doctorData?['name'] ?? 'Unknown Doctor'),
                    subtitle: Text(chat['lastMessage'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                            chatId: chat.id,
                            doctorId: doctorId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatelessWidget {
  final String chatId;
  final String doctorId;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with Doctor $doctorId"),
      ),
      body: const Center(
        child: Text("Chat details here..."),
      ),
    );
  }
}
