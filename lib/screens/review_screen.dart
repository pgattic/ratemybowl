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
  final Map<int, int> _confirmedAttributeRatings = {};
  Attribute? _pendingAttribute;
  int _pendingRating = 3;
  bool _isLoadingAttributes = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;

    _randomHint = (_hints..shuffle()).first;
    _loadAttributes();
  }
  
  void _loadAttributes() {
    setState(() {
      _allAttributes = AttributeService.instance.attributes;
      _isLoadingAttributes = false;
    });
  }
  
  void _selectPendingAttribute(Attribute attribute) {
    setState(() {
      _pendingAttribute = attribute;
      _pendingRating = 3;
    });
  }
  
  void _confirmPendingAttribute() {
    if (_pendingAttribute != null) {
      setState(() {
        _confirmedAttributeRatings[_pendingAttribute!.id] = _pendingRating;
        _pendingAttribute = null;
        _pendingRating = 3;
      });
    }
  }
  
  void _cancelPendingAttribute() {
    setState(() {
      _pendingAttribute = null;
      _pendingRating = 3;
    });
  }
  
  void _removeConfirmedAttribute(int attributeId) {
    setState(() {
      _confirmedAttributeRatings.remove(attributeId);
    });
  }
  
  void _updatePendingRating(int rating) {
    setState(() {
      _pendingRating = rating;
    });
  }
  
  List<Attribute> get _availableAttributes {
    final usedIds = _confirmedAttributeRatings.keys.toSet();
    if (_pendingAttribute != null) {
      usedIds.add(_pendingAttribute!.id);
    }
    return _allAttributes.where((attr) => !usedIds.contains(attr.id)).toList();
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
      final reviewAttributes = _confirmedAttributeRatings.entries
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
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  borderRadius: 16,
                  maxLength: 400,
                ),
              ),

              const SizedBox(height: 16),
              
              if (!_isLoadingAttributes && _allAttributes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Attributes (Optional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                if (_pendingAttribute == null && _availableAttributes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Attribute>(
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('Add an attribute...', style: TextStyle(color: Colors.grey)),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: (_availableAttributes.toList()
                        ..sort((a, b) =>
                            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())))
                          .map((attribute) {
                        return DropdownMenuItem<Attribute>(
                          value: attribute,
                          child: Row(
                            children: [
                              Icon(
                                attribute.icon,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(attribute.displayName, style: const TextStyle(color: Colors.black)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (attribute) {
                        if (attribute != null) {
                          _selectPendingAttribute(attribute);
                        }
                      },
                    ),
                  ),
                
                if (_pendingAttribute != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _pendingAttribute!.icon,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pendingAttribute!.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Rating: ', style: TextStyle(color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _pendingRating.toDouble(),
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                label: _pendingRating.toString(),
                                onChanged: (value) {
                                  _updatePendingRating(value.round());
                                },
                                activeColor: Colors.black,
                                inactiveColor: Colors.grey,
                              ),
                            ),
                            Text(
                              _pendingRating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _cancelPendingAttribute,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _confirmPendingAttribute,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                if (_confirmedAttributeRatings.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Added Attributes:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._confirmedAttributeRatings.entries
                      .map((entry) {
                        final attribute = Attribute.fromId(entry.key);
                        if (attribute == null) return null;
                        return (attribute: attribute, rating: entry.value);
                      })
                      .whereType<({Attribute attribute, int rating})>()
                      .map((item) {
                    final attribute = item.attribute;
                    final rating = item.rating;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            attribute.icon,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attribute.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ...List.generate(5, (i) {
                            return Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _removeConfirmedAttribute(attribute.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                
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
