import 'package:flutter/material.dart';

class VerifyPending extends StatelessWidget {
  const VerifyPending({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Your account is pending admin approval.\nYou will be notified once approved.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
