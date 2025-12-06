import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/attribute.dart';

class AttributeService {
  static final AttributeService instance = AttributeService._();
  AttributeService._();
  final BackendAdapter _backend = backendAdapter;

  List<Attribute> _cachedAttributes = [];
  Map<int, Attribute> _attributeById = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _cachedAttributes = await _backend.getAllAttributes();
      _attributeById = {
        for (final attr in _cachedAttributes) attr.id: attr,
      };
      _isInitialized = true;
      debugPrint('AttributeService: Cached ${_cachedAttributes.length} attributes');
    } catch (e) {
      debugPrint('Error initializing attribute cache: $e');
      _cachedAttributes = [];
      _attributeById = {};
    }
  }

  Future<void> refreshCache() async {
    _isInitialized = false;
    await initialize();
  }

  List<Attribute> get attributes => List.unmodifiable(_cachedAttributes);

  Attribute? getAttributeById(int id) => _attributeById[id];

  Attribute getAttributeByIdOrDefault(int id) {
    return _attributeById[id] ?? Attribute(
      id: id,
      displayName: 'Unknown',
      icon: 'e157',
    );
  }

  Future<List<Attribute>> getAllAttributes() async {
    if (!_isInitialized) {
      await initialize();
    }
    return attributes;
  }

  Future<Map<int, double>> getAttributeAveragesByRestroomId(int restroomId) async {
    try {
      return await _backend.getAttributeAveragesByRestroomId(restroomId);
    } catch (e) {
      debugPrint('Error fetching attribute averages: $e');
      return {};
    }
  }
}

