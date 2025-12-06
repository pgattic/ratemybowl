import 'package:flutter/material.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/attribute.dart';

class AttributeService {
  static final AttributeService instance = AttributeService._();
  AttributeService._();
  final BackendAdapter _backend = backendAdapter;

  List<Attribute> get attributes => Attribute.all;

  Attribute? getAttributeById(int id) => Attribute.fromId(id);

  Future<Map<int, double>> getAttributeAveragesByRestroomId(int restroomId) async {
    try {
      return await _backend.getAttributeAveragesByRestroomId(restroomId);
    } catch (e) {
      debugPrint('Error fetching attribute averages: $e');
      return {};
    }
  }
}
