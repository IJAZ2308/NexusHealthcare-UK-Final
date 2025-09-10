import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;

  const ChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('chats');

  String get chatRoomId {
    // unique chat room id (doctorId_patientId)
    return widget.doctorId.hashCode <= widget.patientId.hashCode
        ? "${widget.doctorId}_${widget.patientId}"
        : "${widget.patientId}_${widget.doctorId}";
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final isDoctor = user.uid == widget.doctorId;
    final senderName = isDoctor ? widget.doctorName : widget.patientName;

    await _db.child(chatRoomId).child('messages').push().set({
      "senderId": user.uid,
      "senderName": senderName,
      "text": _controller.text.trim(),
      "timestamp": ServerValue.timestamp,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.doctorName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _db
                  .child(chatRoomId)
                  .child('messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dbEvent = snapshot.data as DatabaseEvent;
                final messagesMap =
                    dbEvent.snapshot.value as Map<dynamic, dynamic>?;

                if (messagesMap == null) {
                  return const Center(child: Text("No messages yet"));
                }

                final messagesList = messagesMap.entries.toList()
                  ..sort((a, b) {
                    final t1 = a.value['timestamp'] as int? ?? 0;
                    final t2 = b.value['timestamp'] as int? ?? 0;
                    return t1.compareTo(t2);
                  });

                return ListView.builder(
                  reverse: false,
                  itemCount: messagesList.length,
                  itemBuilder: (context, index) {
                    final msg = messagesList[index].value;
                    final isMe =
                        msg['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['senderName'] ?? "Unknown",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[200] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msg['text'] ?? ""),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      hintText: "Type a message...",
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
