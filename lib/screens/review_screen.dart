import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rate_my_bowl/widgets/toilet_paper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/review_service.dart';
import '../models/review.dart';

class ReviewScreen extends StatefulWidget {
  final TextEditingController? controller;
  final String restroomName;
  final int? restroomId;

  const ReviewScreen({
    super.key,
    this.controller,
    required this.restroomName,
    this.restroomId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  double _rating = 3.0; // 1..5, slider snaps to integers

  static const int maxSheets = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  int get _currentSheetIndex => _rating.round().clamp(1, maxSheets);
  Future<void> _submitReview() async {
    final note = _controller.text.trim();

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.restroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Restroom ID not provided'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: You must be logged in to submit a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = Review(
        restroomId: widget.restroomId!,
        userId: user.id,
        stars: _rating.round(),
        reviewDt: DateTime.now(),
        notes: note.isEmpty ? null : note,
      );

      await ReviewService.instance.addReview(review);

      if (mounted) {
        Navigator.of(context).pop(review);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  widget.restroomName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Toilet paper widget — horizontally oriented
              AnimatedToiletPaperRoll(
                sheets: _currentSheetIndex,
                maxSheets: 5,
                width: MediaQuery.of(context).size.width - 48,
                rollSizeFactor: 0.5,
              ),

              // Slider beneath the TP
              Slider(
                value: _rating,
                min: 1.0,
                max: maxSheets.toDouble(),
                divisions: maxSheets - 1, // snaps to integers
                label: _currentSheetIndex.toString(),
                onChanged: (double value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 400,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    hintText: "It smelled like...",
                    hintStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
