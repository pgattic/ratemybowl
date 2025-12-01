import 'package:flutter/material.dart';
import 'package:rate_my_bowl/screens/adding_restroom_screen.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String? _lastReviewText;
  double? _lastRating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug page here',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, double>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddingRestroomScreen(),
                      ),
                    );
                    if (result != null &&
                        result['latitude'] != null &&
                        result['longitude'] != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Restroom added at Lat: ${result['latitude']}, Lng: ${result['longitude']}',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Screen'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ReviewScreen(restroomName: 'Sample Restroom'),
                      ),
                    );
                    if (result != null &&
                        result['text'] != null &&
                        (result['text'] as String).isNotEmpty) {
                      setState(() {
                        _lastReviewText = result['text'] as String;
                        _lastRating = (result['rating'] as num).toDouble();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review received')),
                      );
                    }
                  },
                  child: const Text(
                    'Review',
                    style: TextStyle(color: Color.fromARGB(255, 25, 109, 177)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastReviewText != null) ...[
              Text(
                'Last review: $_lastReviewText',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Rating: ${_lastRating?.toStringAsFixed(1) ?? '-'}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
