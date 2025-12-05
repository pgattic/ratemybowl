import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/models/attribute.dart';
import 'package:rate_my_bowl/models/review_attribute.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:rate_my_bowl/services/attribute_service.dart';
import 'package:rate_my_bowl/widgets/custom_input_field.dart';
import 'package:rate_my_bowl/widgets/toilet_paper.dart';
import '../services/review_service.dart';
import '../models/review.dart';

final List<String> _hints = [
  "It smelled like...",
  "Were the stall doors low enough?",
  "Ran out of toilet paper?",
  "It reminded me of...",
  "Feeling refreshed?",
];

late String _randomHint;

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
  double _rating = 3.0;

  static const int maxSheets = 5;
  bool _isSubmitting = false;
  
  List<Attribute> _allAttributes = [];
  Map<int, int> _selectedAttributeRatings = {}; // attributeId -> rating (1-5)
  bool _isLoadingAttributes = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;

    _randomHint = (_hints..shuffle()).first;
    _loadAttributes();
  }
  
  Future<void> _loadAttributes() async {
    try {
      final attributes = await AttributeService.instance.getAllAttributes();
      if (mounted) {
        setState(() {
          _allAttributes = attributes;
          _isLoadingAttributes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAttributes = false;
        });
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
  
  void _addAttribute(Attribute attribute) {
    setState(() {
      _selectedAttributeRatings[attribute.id] = 3;
    });
  }
  
  void _removeAttribute(int attributeId) {
    setState(() {
      _selectedAttributeRatings.remove(attributeId);
    });
  }
  
  void _updateAttributeRating(int attributeId, int rating) {
    setState(() {
      _selectedAttributeRatings[attributeId] = rating;
    });
  }
  
  List<Attribute> get _availableAttributes {
    final selectedIds = _selectedAttributeRatings.keys.toSet();
    return _allAttributes.where((attr) => !selectedIds.contains(attr.id)).toList();
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

    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;
    if (userId == null) {
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
      final reviewAttributes = _selectedAttributeRatings.entries
          .map((entry) => ReviewAttribute(
                reviewId: 0,
                attributeId: entry.key,
                rating: entry.value,
              ))
          .toList();
      
      final review = Review(
        restroomId: widget.restroomId!,
        userId: userId,
        stars: _rating.round(),
        reviewDt: DateTime.now(),
        notes: note.isEmpty ? null : note,
        attributes: reviewAttributes,
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
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Slider(
                  value: _rating,
                  min: 1.0,
                  max: maxSheets.toDouble(),
                  divisions: maxSheets - 1,
                  label: _currentSheetIndex.toString(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomInputField(
                  hintText: _randomHint,
                  controller: _controller,
                  minLines: 4,
                  maxLines: 8,
                  borderRadius: 16,
                  maxLength: 400,
                ),
              ),

              const SizedBox(height: 16),
              
              if (!_isLoadingAttributes && _allAttributes.isNotEmpty) ...[
                const Text(
                  'Attributes (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (_availableAttributes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Attribute>(
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('Add an attribute...'),
                      ),
                      isExpanded: true,
                      items: _availableAttributes.map((attribute) {
                        return DropdownMenuItem<Attribute>(
                          value: attribute,
                          child: Row(
                            children: [
                              Icon(
                                _getIconFromHex(attribute.icon),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(attribute.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (attribute) {
                        if (attribute != null) {
                          _addAttribute(attribute);
                        }
                      },
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                ..._selectedAttributeRatings.entries.map((entry) {
                  final attribute = _allAttributes.firstWhere(
                    (attr) => attr.id == entry.key,
                  );
                  final rating = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getIconFromHex(attribute.icon),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  attribute.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeAttribute(attribute.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Rating: '),
                            Expanded(
                              child: Slider(
                                value: rating.toDouble(),
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                label: rating.toString(),
                                onChanged: (value) {
                                  _updateAttributeRating(
                                    attribute.id,
                                    value.round(),
                                  );
                                },
                              ),
                            ),
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
              ],

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
