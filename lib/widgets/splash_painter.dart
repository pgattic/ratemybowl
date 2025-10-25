// import 'dart:math';

// import 'package:flutter/material.dart';

// class ToiletPainter extends CustomPainter {
//   final double handleAngle;
//   final double waterLevel;
//   final double t;
//   final double pouringStreamY;
//   final bool pouringStreamDone;
//   final Color textColor;

//   ToiletPainter({
//     required this.handleAngle,
//     required this.waterLevel,
//     required this.t,
//     required this.pouringStreamY,
//     required this.pouringStreamDone,
//     required this.textColor,
//   });

// @override
// void paint(Canvas canvas, Size size) {
//   final paint = Paint();

//   // --- Background
//   canvas.drawRect(
//     Rect.fromLTWH(0, 0, size.width, size.height),
//     Paint()..color = Colors.white,
//   );

//   // --- Water surface (simplified)
//   if (waterLevel > 0) {
//     final waveTopY = size.height - waterLevel;
//     final path = Path();
//     path.moveTo(0, size.height);
//     path.lineTo(0, waveTopY);

//     double phaseX = t * 0.15;
//     for (double x = -60; x <= size.width + 60; x += 1) {
//       double baseWave = sin(x * 0.03 + phaseX) * 22;
//       double noiseWave = 0; // placeholder, you can add Perlin noise
//       path.lineTo(x, waveTopY + baseWave + noiseWave);
//     }

//     path.lineTo(size.width, waveTopY);
//     path.lineTo(size.width, size.height);
//     path.close();

//     canvas.drawPath(
//       path,
//       Paint()..color = const Color.fromARGB(255, 35, 200, 250),
//     );
//   }

//   // --- Main text
//   final txt = 'r  te my   owl'; // "b" replaced with space
//   final textPainter = TextPainter(
//     text: TextSpan(
//       text: txt,
//       style: TextStyle(
//         fontSize: 50,
//         fontWeight: FontWeight.bold,
//         color: textColor,
//         fontFamily: 'Quicksand',
//       ),
//     ),
//     textAlign: TextAlign.center,
//     textDirection: TextDirection.ltr,
//   );
//   textPainter.layout();
//   final textX = (size.width - textPainter.width) / 2;
//   final textY = size.height / 2;
//   textPainter.paint(canvas, Offset(textX, textY));

//   // --- Toilet image in place of "b"
//   if (toiletImg != null) {
//     final toiletX = textX + 58; // adjust based on your font metrics
//     final toiletY = textY;
//     final imgWidth = 30.0;
//     final imgHeight = 40.0;

//     canvas.save();
//     canvas.translate(toiletX, toiletY);
//     // Center the image on the text baseline
//     canvas.drawImageRect(
//       toiletImg!,
//       Rect.fromLTWH(0, 0, toiletImg!.width.toDouble(), toiletImg!.height.toDouble()),
//       Rect.fromCenter(center: Offset(0, 0), width: imgWidth, height: imgHeight),
//       Paint()..colorFilter = ColorFilter.mode(textColor, BlendMode.modulate),
//     );
//     canvas.restore();
//   }

//   // --- Rotating handle ("a")
//   canvas.save();
//   final handleX = textX - 122;
//   final handleY = textY;
//   canvas.translate(handleX, handleY);
//   canvas.rotate(handleAngle);

//   final handlePainter = TextPainter(
//     text: TextSpan(
//       text: 'a',
//       style: TextStyle(
//         fontSize: 50,
//         fontWeight: FontWeight.bold,
//         color: textColor,
//         fontFamily: 'Quicksand',
//       ),
//     ),
//     textAlign: TextAlign.center,
//     textDirection: TextDirection.ltr,
//   );
//   handlePainter.layout();
//   handlePainter.paint(canvas, Offset(-handlePainter.width / 2, -handlePainter.height / 2));
//   canvas.restore();
// }

// }
