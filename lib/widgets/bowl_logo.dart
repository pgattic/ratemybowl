import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/svg.dart';

class RateMyBowlLogo extends StatelessWidget {
  const RateMyBowlLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "rate my ",
          style: GoogleFonts.quicksand(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SvgPicture.asset("assets/toilet.svg", width: 32, height: 32),
        Text(
          "owl",
          style: GoogleFonts.quicksand(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
