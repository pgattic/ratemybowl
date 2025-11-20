import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RateMyBowlLogo extends StatelessWidget {
  final Color? color; // optional color
  final double size;
  final MainAxisAlignment alignment;

  const RateMyBowlLogo({
    super.key,
    this.color,
    this.size = 1.0,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final useColor = color ?? Colors.white; // default to white
    final fontSize = 36.0;
    final iconSize = 30.0;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Text("rate my ", style: TextStyle(fontSize: fontSize * size)),
        SvgPicture.asset(
          "assets/toilet.svg",
          width: iconSize * size,
          height: iconSize * size,
          colorFilter: ColorFilter.mode(useColor, BlendMode.srcIn),
        ),
        Text("owl", style: TextStyle(fontSize: fontSize * size)),
      ],
    );
  }
}
