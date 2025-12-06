import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attribute.dart';
import '../models/restroom.dart';
import '../models/review.dart';
import '../services/attribute_service.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';

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
  Map<int, double> _attributeAverages = {};
  List<Attribute> _allAttributes = [];
  bool _isLoadingAttributes = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadAttributeAverages();
  }
  
  Future<void> _loadAttributeAverages() async {
    if (widget.restroom.id == null) return;
    
    setState(() => _isLoadingAttributes = true);
    
    try {
      final attributes = await AttributeService.instance.getAllAttributes();
      final averages = await AttributeService.instance
          .getAttributeAveragesByRestroomId(widget.restroom.id!);
      
      if (mounted) {
        setState(() {
          _allAttributes = attributes;
          _attributeAverages = averages;
          _isLoadingAttributes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attribute averages: $e');
      if (mounted) {
        setState(() => _isLoadingAttributes = false);
      }
    }
  }
  
  IconData _getIconFromHex(String hexCode) {
    try {
      final codePoint = int.parse(hexCode, radix: 16);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.star;
    }
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

                // Attribute averages display
                if (!_isLoadingAttributes && _attributeAverages.isNotEmpty) ...[
                  const Text(
                    'Attribute Ratings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: (_attributeAverages.entries
                        .map((entry) {
                          final attribute = _allAttributes.firstWhere(
                            (attr) => attr.id == entry.key,
                            orElse: () => Attribute(
                              id: entry.key,
                              displayName: 'Unknown',
                              icon: 'e157',
                            ),
                          );
                          return (attribute: attribute, average: entry.value);
                        })
                        .toList()
                      ..sort((a, b) => a.attribute.displayName
                          .toLowerCase()
                          .compareTo(b.attribute.displayName.toLowerCase())))
                        .map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconFromHex(item.attribute.icon),
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.attribute.displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.average.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

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
                              _loadAttributeAverages();
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
                        color: Color.fromARGB(255, 40, 125, 165),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ..._reviews.map((review) {
                    return Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final currentUserId = authService.currentUserId;
                        final isCurrentUser = currentUserId != null &&
                            currentUserId == review.userId;
                        final userName = review.displayName ?? 'Anonymous';
                        final displayText = isCurrentUser ? '$userName (you)' : userName;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      displayText,
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
                                ),
                                if (review.notes != null &&
                                    review.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    review.notes!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 64, 64, 64),
                                    ),
                                  ),
                                ],
                                if (review.attributes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (review.attributes
                                      .map((attr) {
                                        final attribute = _allAttributes.firstWhere(
                                          (a) => a.id == attr.attributeId,
                                          orElse: () => Attribute(
                                            id: attr.attributeId,
                                            displayName: 'Unknown',
                                            icon: 'e157',
                                          ),
                                        );
                                        
                                        return (attr: attr, attribute: attribute);
                                      })
                                      .toList()
                                      ..sort((a, b) => a.attribute.displayName
                                          .toLowerCase()
                                          .compareTo(b.attribute.displayName.toLowerCase()))
                                    )
                                    .map((item) {
                                      final attr = item.attr;
                                      final attribute = item.attribute;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getIconFromHex(attribute.icon),
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${attribute.displayName}: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          ...List.generate(5, (i) {
                                            return Icon(
                                              i < attr.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 12,
                                            );
                                          }),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
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
