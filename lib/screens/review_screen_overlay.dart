import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rate_my_bowl/widgets/toilet_paper.dart';

/// REVIEW SCREEN + TOILET PAPER WIDGET
/// Copy into your project. This file contains:
/// - ReviewScreen (your original screen, slightly adapted)
/// - ToiletPaperWidget (standalone, reusable)
/// - _ToiletPaperPainter (simple CustomPainter)

class ReviewScreen extends StatefulWidget {
  final TextEditingController? controller;
  final bool obscureText;
  final String hintText;

  const ReviewScreen({
    super.key,
    this.controller,
    this.obscureText = false,
    required this.hintText,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  double _rating = 3.0; // 1..5, slider snaps to integers

  static const int maxSheets = 5;

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
              const Center(
                child: Text(
                  'Review page here',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Rating (sheets): ${_currentSheetIndex.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              // --- Toilet Paper overlaid onto Slider ---
              SizedBox(
                height: 180, // enough room for roll + overlap
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- Slider (behind the toilet paper) ---
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Slider(
                        value: _rating,
                        min: 1.0,
                        max: maxSheets.toDouble(),
                        divisions: maxSheets - 1,
                        label: _currentSheetIndex.toString(),
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ),

                    // --- Toilet Paper widget on top of slider ---
                    Positioned(
                      top: 50, // adjust to taste — makes roll overlap slider
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: true, // slider remains interactive
                        child: AnimatedToiletPaperRoll(
                          sheets: _currentSheetIndex,
                          maxSheets: maxSheets,
                          width: MediaQuery.of(context).size.width - 48,
                          rollSizeFactor: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // // Toilet paper widget — horizontally oriented
              // AnimatedToiletPaperRoll(
              //   sheets:
              //       _currentSheetIndex, // int 1..maxSheets (your slider snaps)
              //   maxSheets: 5,
              //   width: MediaQuery.of(context).size.width - 48,
              //   rollSizeFactor: 0.5,
              // ),

              // // const SizedBox(height: 16),

              // // const SizedBox(height: 12),

              // // Slider beneath the TP; your slider already snaps (divisions: 4)
              // Slider(
              //   value: _rating,
              //   min: 1.0,
              //   max: maxSheets.toDouble(),
              //   divisions: maxSheets - 1, // snaps to integers
              //   label: _currentSheetIndex.toString(),
              //   onChanged: (double value) {
              //     setState(() {
              //       _rating = value;
              //     });
              //   },
              // ),
              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _controller,
                  obscureText: widget.obscureText,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    hintText: widget.hintText,
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
                    onPressed: () {
                      final note = _controller.text.trim();
                      final result = {'text': note, 'rating': _rating};
                      if (note.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a review note'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(result);
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _controller.clear();
                        _rating = 3.0;
                      });
                      FocusScope.of(context).unfocus();
                      final note = _controller.text.trim();
                      final result = {'text': note, 'rating': _rating};
                      Navigator.of(context).pop(result);
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
