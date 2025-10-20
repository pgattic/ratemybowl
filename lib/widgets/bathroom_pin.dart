import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BathroomType {
  men,
  women,
  other,
}

class BathroomPin extends StatelessWidget {
  final List<BathroomType> bathroomTypes;
  final bool isSelected; // not doing anything with this yet, but I added it in just in case we want to change the icon when selected or something
  final VoidCallback? onTap;

  const BathroomPin({
    super.key,
    required this.bathroomTypes,
    this.isSelected = false,
    this.onTap,
  });

  String _getSvgAssetPath() {
    final sortedTypes = List<BathroomType>.from(bathroomTypes);
    sortedTypes.sort((a, b) => a.index.compareTo(b.index));
    
    if (sortedTypes.length == 1) {
      switch (sortedTypes[0]) {
        case BathroomType.men:
          return 'assets/toilet_pin_m.svg';
        case BathroomType.women:
          return 'assets/toilet_pin_f.svg';
        case BathroomType.other:
          return 'assets/toilet_pin_u.svg';
      }
    } else if (sortedTypes.length == 2) {
      if (sortedTypes.contains(BathroomType.men) && sortedTypes.contains(BathroomType.women)) {
        return 'assets/toilet_pin_mf.svg';
      }
      if (sortedTypes.contains(BathroomType.men) && sortedTypes.contains(BathroomType.other)) {
        return 'assets/toilet_pin_mfu.svg';
      }
      if (sortedTypes.contains(BathroomType.women) && sortedTypes.contains(BathroomType.other)) {
        return 'assets/toilet_pin_mfu.svg';
      }
    } else if (sortedTypes.length == 3) {
      return 'assets/toilet_pin_mfu.svg';
    }
    
    return 'assets/toilet_pin_u.svg';
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _getSvgAssetPath();
    final pinHeight = 50.0; // if we swap out the icon SVGs, we'll need to adjust this value to match the new height
    
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: Offset(0, pinHeight / -2.0),
        child: SvgPicture.asset(
          iconPath,
        ),
      ),
    );
  }
}

