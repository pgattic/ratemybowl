import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  double _rating = 3.0;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlueAccent[200],
      child: Center(
        child: Column(
          children: [
            const Text(
              'Review page here',
              style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              ),
            ),
            Text(
                'Rating: ${_rating.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
            ),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: _rating.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            TextField(
              controller: _controller,
              obscureText: widget.obscureText,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // ignore: avoid_print
                    print('review: ${_controller.text}, rating: $_rating');
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
                  },
                  child: const Text('Cancel'),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }
}