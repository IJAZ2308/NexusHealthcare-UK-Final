import 'package:dr_shahin_uk/screens/register_doctor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👈 import your doctor registration page

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

  void _resubmitDocuments() {
    // 👉 Instead of logging out, send to registration screen again
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterDoctorScreen()),
    );
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
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
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

  Widget _getStatusIcon() {
    switch (widget.status?.toLowerCase()) {
      case "approved":
        return const Icon(Icons.check_circle, size: 80, color: Colors.green);
      case "rejected":
        return const Icon(Icons.cancel, size: 80, color: Colors.red);
      default:
        return const Icon(
          Icons.hourglass_empty,
          size: 80,
          color: Colors.orange,
        );
    }
  }

  Widget _getStatusMessage() {
    switch (widget.status?.toLowerCase()) {
      case "approved":
        return const Column(
          children: [
            Text(
              "Congratulations! Your account has been approved.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "You can now access all doctor features.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        );
      case "rejected":
        return const Column(
          children: [
            Text(
              "Sorry, your account was rejected.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "Please resubmit your documents for review.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        );
      default:
        return const Column(
          children: [
            Text(
              "Your account is under review by admin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "You will be notified once your account is approved or rejected.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = widget.status?.toLowerCase() == "rejected";

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
            // Status header
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
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
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

            // Status icon + message
            _getStatusIcon(),
            const SizedBox(height: 20),
            _getStatusMessage(),
            const SizedBox(height: 40),

            // Show resubmit button if rejected
            if (isRejected)
              ElevatedButton.icon(
                onPressed: _resubmitDocuments,
                icon: const Icon(Icons.upload_file),
                label: const Text("Resubmit Documents"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            if (isRejected) const SizedBox(height: 20),

            // Logout button
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
