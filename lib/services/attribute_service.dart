import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/attribute.dart';

class AttributeService {
  static final AttributeService instance = AttributeService._();
  AttributeService._();
  final BackendAdapter _backend = backendAdapter;

  Future<List<Attribute>> getAllAttributes() async {
    try {
      return await _backend.getAllAttributes();
    } catch (e) {
      debugPrint('Error fetching attributes: $e');
      return [];
    }
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

