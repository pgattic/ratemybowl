import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final int minLines;
  final int maxLines;
  final double borderRadius;
  final int? maxLength;
  final TextInputType? keyboardType;

  const CustomInputField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.minLines = 1,
    this.maxLines = 1,
    this.borderRadius = 50.0,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(color: const Color.fromARGB(255, 64, 64, 64)),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          // Add this here
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              36,
              113,
              175,
            ), // Change to whatever color you want
            width: 2.0,
          ),
        ),
        hintText: hintText,
        filled: true,
        fillColor: scheme.onPrimary,
      ),
    );
  }
}
