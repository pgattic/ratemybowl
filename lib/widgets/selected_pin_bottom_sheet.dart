import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restroom.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class SelectedPinBottomSheet extends StatefulWidget {
  final Restroom restroom;
  final Widget Function(BuildContext) screenBuilder;

  const SelectedPinBottomSheet({
    super.key,
    required this.restroom,
    required this.screenBuilder,
  });

  @override
  State<SelectedPinBottomSheet> createState() => _SelectedPinBottomSheetState();
}

class _SelectedPinBottomSheetState extends State<SelectedPinBottomSheet> {
  Map<String, Object>? display;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);

    try {
      final reviews = await ReviewService.instance.getReviewsByRestroomId(
        widget.restroom.id!,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  String _getGenderDisplayName(Gender gender) {
    return switch (gender) {
      Gender.male => 'Men\'s',
      Gender.female => 'Women\'s',
      Gender.unisex => 'Unisex',
    };
  }

  IconData _genderIcon(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.man;
      case Gender.female:
        return Icons.woman;
      default:
        return Icons.wc;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final Uri mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl);
    } else {
      debugPrint('Could not launch $mapsUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final restroom = widget.restroom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(64, 196, 255, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                Text(
                  restroom.name,
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
                          restroom.rating > 0
                              ? restroom.rating.toStringAsFixed(1)
                              : 'No ratings',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.reviews,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restroom.reviewCount} ${restroom.reviewCount == 1 ? 'review' : 'reviews'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _genderIcon(widget.restroom.gender),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getGenderDisplayName(restroom.gender),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(
                  color: Color.fromARGB(255, 40, 125, 165),
                  height: 32,
                ),

                if (display != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'review: $display',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: widget.screenBuilder),
                          );

                          if (result != null) {
                            setState(() {
                              display = result is Map
                                  ? Map<String, Object>.from(result)
                                  : {'result': result.toString()};
                            });

                            if (result is Map && result['success'] == true) {
                              _loadReviews();
                            }

                            Navigator.of(context).pop(result);
                          }
                        },
                        child: const Text('Add review'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final loc = restroom.coordinates;
                          _launchGoogleMaps(loc.latitude, loc.longitude);
                        },
                        child: const Text('Navigate'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(
                  color: Color.fromARGB(255, 40, 125, 165),
                  height: 0,
                ),
                const SizedBox(height: 8),

                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                if (_isLoadingReviews)
                  const Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (review.displayName != null)
                                Text(
                                  review.displayName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  'Anonymous',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    return Icon(
                                      i < review.stars
                                          ? Icons.star
                                          : Icons.star_border,
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
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
