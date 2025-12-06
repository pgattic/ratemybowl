import 'package:flutter/material.dart';

enum Attribute {
  toiletPaperQuality(1, 'Toilet Paper Quality', Icons.gradient),
  babyChangingStation(2, 'Baby Changing Station', Icons.baby_changing_station),
  handDryingOptions(3, 'Hand-Drying Options', Icons.dry),
  wheelchairAccessibility(4, 'Wheelchair Accessibility', Icons.wheelchair_pickup),
  feminineHygieneProducts(5, 'Feminine Hygiene Products', Icons.female),
  easeOfAccess(6, 'Ease of Access', Icons.key),
  bidet(7, 'Bidet', Icons.shower),
  smell(8, 'Smell', Icons.local_florist);

  final int id;
  final String displayName;
  final IconData icon;

  const Attribute(this.id, this.displayName, this.icon);

  static Attribute? fromId(int id) {
    for (final attr in Attribute.values) {
      if (attr.id == id) return attr;
    }
    return null;
  }

  static List<Attribute> get all => Attribute.values;
}
