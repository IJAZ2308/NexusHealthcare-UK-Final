import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UpdateBedsScreen extends StatefulWidget {
  const UpdateBedsScreen({super.key});

  @override
  State<UpdateBedsScreen> createState() => _UpdateBedsScreenState();
}

class _UpdateBedsScreenState extends State<UpdateBedsScreen> {
  final DatabaseReference _bedsRef = FirebaseDatabase.instance.ref().child(
    'beds',
  );

  int _totalBeds = 0;
  int _availableBeds = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Listen to real-time changes
    _bedsRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _totalBeds = data['totalBeds'] ?? 0;
            _availableBeds = data['availableBeds'] ?? 0;
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  Future<void> _updateBeds() async {
    if (_availableBeds > _totalBeds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Available beds cannot exceed total beds"),
        ),
      );
      return;
    }

    try {
      await _bedsRef.set({
        'totalBeds': _totalBeds,
        'availableBeds': _availableBeds,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bed availability updated successfully"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update beds: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Bed Availability")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _totalBeds.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Total Beds",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _totalBeds = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _availableBeds.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Available Beds",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _availableBeds = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateBeds,
                      child: const Text("Update Beds"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
