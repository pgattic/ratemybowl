import 'package:flutter/material.dart';
import '../models/restroom.dart';
import '../models/review.dart';
import '../services/review_service.dart';

enum BottomSheetType {
  review,
  restroom;

  String get displayName {
    return switch (this) {
      BottomSheetType.review => 'review',
      BottomSheetType.restroom => 'restroom',
    };
  }
}

class RmbBottomSheet extends StatefulWidget {
  final Widget Function(BuildContext) screenBuilder;
  final BottomSheetType addType;
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
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    if (widget.restroom?.id != null) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (widget.restroom?.id == null) return;

    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviews = await ReviewService.instance.getReviewsByRestroomId(widget.restroom!.id!);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  String _getGenderDisplayName(Gender gender) {
    return switch (gender) {
      Gender.Male => 'Men\'s',
      Gender.Female => 'Women\'s',
      Gender.Unisex => 'Unisex',
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Padding(
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
                '${widget.addType.displayName}: $display',
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
                  
                  if (result is Map && result['success'] == true) {
                    _loadReviews();
                  }
                  
                  Navigator.of(context).pop(result);
                }
              },
              child: Text('Add ${widget.addType.displayName}'),
            ),
          ),
          if (widget.restroom != null && widget.addType == BottomSheetType.review) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Reviews',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No reviews yet. Be the first to review!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._reviews.map((review) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < review.stars ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(review.reviewDt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (review.notes != null && review.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
            ],
          ),
        ),
      ),
    );
  }
}
