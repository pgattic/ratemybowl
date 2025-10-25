import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/svg.dart';

class RateMyBowlLogo extends StatelessWidget {
  final Color? textColor; // optional color

  const RateMyBowlLogo({super.key, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Colors.white; // default to white
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "rate my ",
          style: GoogleFonts.quicksand(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SvgPicture.asset(
          "assets/toilet.svg",
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        Text(
          "owl",
          style: GoogleFonts.quicksand(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
