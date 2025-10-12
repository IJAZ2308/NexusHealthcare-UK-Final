import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_shahin_uk/screens/lib/screens/models/doctor.dart';

class DoctorCard extends StatefulWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  late double averageRating;
  late int numberOfReviews;
  late double totalReviews;

  @override
  void initState() {
    super.initState();
    totalReviews = widget.doctor.totalReviews as double;
    numberOfReviews = widget.doctor.numberOfReviews;
    averageRating = numberOfReviews > 0 ? totalReviews / numberOfReviews : 0;
  }

  Future<void> _writeReview(BuildContext context) async {
    final TextEditingController ratingController = TextEditingController();
    final TextEditingController reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Write a Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Rating (1-5)"),
              ),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(labelText: "Review Comment"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final double rating =
                    double.tryParse(ratingController.text) ?? 0;
                if (rating <= 0 || rating > 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter a valid rating between 1-5"),
                    ),
                  );
                  return;
                }

                final doctorRef = FirebaseFirestore.instance
                    .collection("doctors")
                    .doc(widget.doctor.uid);

                // Update Firestore
                await doctorRef.update({
                  "totalReviews": FieldValue.increment(rating),
                  "numberOfReviews": FieldValue.increment(1),
                  "reviews": FieldValue.arrayUnion([reviewController.text]),
                });

                // Update local state for real-time UI refresh
                setState(() {
                  totalReviews += rating;
                  numberOfReviews += 1;
                  averageRating = totalReviews / numberOfReviews;
                });

                // ignore: use_build_context_synchronously
                Navigator.of(ctx).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review submitted!")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.doctor.profileImageUrl.isNotEmpty
                      ? NetworkImage(widget.doctor.profileImageUrl)
                      : const AssetImage("assets/images/doctor.png")
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.doctor.firstName} ${widget.doctor.lastName}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.doctor.category} • ${widget.doctor.workingAt}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${averageRating.toStringAsFixed(1)} ($numberOfReviews reviews)",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.doctor.specializations.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: -4,
                          children: widget.doctor.specializations
                              .map(
                                (spec) => Chip(
                                  label: Text(
                                    spec,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _writeReview(context),
              child: const Text("Write Review"),
            ),
          ],
        ),
      ),
    );
  }
}
