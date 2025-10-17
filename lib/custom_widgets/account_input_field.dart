import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountInputField extends StatelessWidget {
  final String hintText;
  final bool obscureText;

  const AccountInputField({
    super.key,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.quicksand(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
