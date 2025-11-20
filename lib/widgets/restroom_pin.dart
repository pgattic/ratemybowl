import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rate_my_bowl/models/restroom.dart';

class RestroomPin extends StatelessWidget {
  final Gender restroomGender;
  final bool isSelected;
  final VoidCallback? onTap;

  const RestroomPin({
    super.key,
    required this.restroomGender,
    this.isSelected = false,
    this.onTap,
  });

  String _getSvgAssetPath() {
    return switch (restroomGender) {
      Gender.male => 'assets/toilet_pin_m.svg',
      Gender.female => 'assets/toilet_pin_f.svg',
      Gender.unisex => 'assets/toilet_pin_u.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    const pinWidth = 40.0;
    const pinHeight = 50.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: pinWidth,
        height: pinHeight,
        child: AnimatedScale(
          scale: isSelected ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: SvgPicture.asset(_getSvgAssetPath(), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
