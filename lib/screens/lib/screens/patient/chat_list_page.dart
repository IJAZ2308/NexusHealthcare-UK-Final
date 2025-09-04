import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child(
    'chats',
  );
  final DatabaseReference _doctorsRef = FirebaseDatabase.instance.ref().child(
    'doctors',
  );

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _chatsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No chats available"));
          }

          final Map<dynamic, dynamic> chatsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Filter chats where user is a participant
          final List<Map<dynamic, dynamic>> userChats = [];
          chatsMap.forEach((key, value) {
            final chat = Map<dynamic, dynamic>.from(value);
            chat['id'] = key;
            final participants = List<dynamic>.from(chat['participants'] ?? []);
            if (participants.contains(user.uid)) {
              userChats.add(chat);
            }
          });

          if (userChats.isEmpty) {
            return const Center(child: Text("No chats available"));
          }

          return ListView.builder(
            itemCount: userChats.length,
            itemBuilder: (context, index) {
              final chat = userChats[index];
              final participants = List<dynamic>.from(
                chat['participants'] ?? [],
              );
              final String doctorId = participants.firstWhere(
                (id) => id != user.uid,
              );

              return FutureBuilder<DatabaseEvent>(
                future: _doctorsRef.child(doctorId).once(),
                builder: (context, doctorSnapshot) {
                  if (!doctorSnapshot.hasData ||
                      doctorSnapshot.data?.snapshot.value == null) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final doctorData = Map<dynamic, dynamic>.from(
                    doctorSnapshot.data!.snapshot.value as Map,
                  );

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(doctorData['name'] ?? 'Unknown Doctor'),
                    subtitle: Text(chat['lastMessage'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                            chatId: chat['id'],
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

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String doctorId;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.doctorId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child(
    'chats',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final String uid = _auth.currentUser!.uid;
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final DatabaseReference messagesRef = _chatsRef
        .child(widget.chatId)
        .child('messages')
        .push();
    messagesRef.set({
      'senderId': uid,
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _chatsRef.child(widget.chatId).update({'lastMessage': message});
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Chat with Doctor ${widget.doctorId}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatsRef.child(widget.chatId).child('messages').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet."));
                }

                final Map<dynamic, dynamic> messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final messages =
                    messagesMap.entries.map((e) {
                      final msg = Map<dynamic, dynamic>.from(e.value);
                      msg['id'] = e.key;
                      return msg;
                    }).toList()..sort(
                      (a, b) => a['timestamp'].compareTo(b['timestamp']),
                    );

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == uid;
                    return ListTile(
                      title: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg['text']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
