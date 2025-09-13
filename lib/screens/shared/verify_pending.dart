import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyPending extends StatefulWidget {
  final String? licenseUrl;
  final String? status; // "pending", "approved", "rejected"

  const VerifyPending({super.key, this.licenseUrl, this.status = "pending"});

  @override
  State<VerifyPending> createState() => _VerifyPendingState();
}

class _VerifyPendingState extends State<VerifyPending> {
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed("/login");
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.status?.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    switch (widget.status?.toLowerCase()) {
      case "approved":
        return "Approved";
      case "rejected":
        return "Rejected";
      default:
        return "Pending Approval";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Status"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: _getStatusColor(), size: 30),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // License image
            if (widget.licenseUrl != null && widget.licenseUrl!.isNotEmpty)
              Column(
                children: [
                  const Text(
                    "Submitted License",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showFullScreenImage(widget.licenseUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.licenseUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap image to view full screen",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Your account is under review by admin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "You will be notified once your account is approved or rejected.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
