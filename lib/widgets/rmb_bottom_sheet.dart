import 'package:flutter/material.dart';
import '../models/restroom.dart';

class RmbBottomSheet extends StatefulWidget {
  final Widget Function(BuildContext) screenBuilder;
  final String addType;
  final Restroom? restroom;
  const RmbBottomSheet({
    super.key,
    required this.addType,
    required this.screenBuilder,
    this.restroom,
  });

  @override
  State<RmbBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<RmbBottomSheet> {
  Map<String, Object>? display;

  String _getGenderDisplayName(Gender gender) {
    return switch (gender) {
      Gender.Male => 'Men\'s',
      Gender.Female => 'Women\'s',
      Gender.Unisex => 'Unisex',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.restroom != null) ...[
            Text(
              widget.restroom!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      widget.restroom!.rating > 0
                          ? widget.restroom!.rating.toStringAsFixed(1)
                          : 'No ratings',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.reviews, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.restroom!.reviewCount} ${widget.restroom!.reviewCount == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.wc, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _getGenderDisplayName(widget.restroom!.gender),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
          ],
          if (display != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '${widget.addType.toLowerCase()}: $display',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: widget.screenBuilder),
                );

                if (result != null) {
                  setState(() {
                    display = result is Map ? Map<String, Object>.from(result) : {'result': result.toString()};
                  });
                  Navigator.of(context).pop(result);
                }
              },
              child: Text('Add ${widget.addType.toLowerCase()}'),
            ),
          ),
        ],
      ),
    );
  }
}
