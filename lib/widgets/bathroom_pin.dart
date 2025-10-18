import 'package:flutter/material.dart';

enum BathroomType {
  men,
  women,
  other,
}

class BathroomPin extends StatelessWidget {
  final List<BathroomType> bathroomTypes;
  final bool isSelected;
  final VoidCallback? onTap;

  const BathroomPin({
    super.key,
    required this.bathroomTypes,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSelected ? 40 : 32,
        height: isSelected ? 50 : 40,
        child: CustomPaint(
          painter: BathroomPinPainter(
            bathroomTypes: bathroomTypes,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

class BathroomPinPainter extends CustomPainter {
  final List<BathroomType> bathroomTypes;
  final bool isSelected;

  BathroomPinPainter({
    required this.bathroomTypes,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    const menColor = Color(0xFF2196F3); // Blue
    const womenColor = Color(0xFFE91E63); // Pink
    const otherColor = Color(0xFF424242); // Black/Gray

    // Calculate dimensions
    final width = size.width;
    final height = size.height;
    final pinRadius = width * 0.45;
    final pinCenterX = width / 2;
    final pinCenterY = pinRadius;
    final pinBottomY = height;
    final triangleTopY = pinCenterY + pinRadius * 0.9;

    final pinPath = Path();
    
    pinPath.addOval(Rect.fromCircle(
      center: Offset(pinCenterX, pinCenterY),
      radius: pinRadius,
    ));
    
    pinPath.moveTo(pinCenterX - pinRadius * 0.3, triangleTopY);
    pinPath.lineTo(pinCenterX + pinRadius * 0.3, triangleTopY);
    pinPath.lineTo(pinCenterX, pinBottomY);
    pinPath.close();

    paint.color = isSelected ? Colors.red : Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = isSelected ? 3 : 2;
    canvas.drawPath(pinPath, paint);

    paint.style = PaintingStyle.fill;

    if (bathroomTypes.length == 1) {
      Color color;
      switch (bathroomTypes[0]) {
        case BathroomType.men:
          color = menColor;
          break;
        case BathroomType.women:
          color = womenColor;
          break;
        case BathroomType.other:
          color = otherColor;
          break;
      }
      paint.color = color;
      canvas.drawPath(pinPath, paint);
    } else if (bathroomTypes.length == 2) {
      final leftPath = Path();
      final rightPath = Path();

      leftPath.addArc(
        Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius),
        -1.5708,
        3.14159,
      );
      leftPath.lineTo(pinCenterX, pinCenterY);
      leftPath.close();

      rightPath.addArc(
        Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius),
        1.5708,
        3.14159,
      );
      rightPath.lineTo(pinCenterX, pinCenterY);
      rightPath.close();

      Color leftColor;
      switch (bathroomTypes[0]) {
        case BathroomType.men:
          leftColor = menColor;
          break;
        case BathroomType.women:
          leftColor = womenColor;
          break;
        case BathroomType.other:
          leftColor = otherColor;
          break;
      }
      paint.color = leftColor;
      canvas.drawPath(leftPath, paint);

      Color rightColor;
      switch (bathroomTypes[1]) {
        case BathroomType.men:
          rightColor = menColor;
          break;
        case BathroomType.women:
          rightColor = womenColor;
          break;
        case BathroomType.other:
          rightColor = otherColor;
          break;
      }
      paint.color = rightColor;
      canvas.drawPath(rightPath, paint);

      final bottomPath = Path();
      bottomPath.moveTo(pinCenterX - pinRadius * 0.3, triangleTopY);
      bottomPath.lineTo(pinCenterX + pinRadius * 0.3, triangleTopY);
      bottomPath.lineTo(pinCenterX, pinBottomY);
      bottomPath.close();
      paint.color = leftColor;
      canvas.drawPath(bottomPath, paint);
    } else if (bathroomTypes.length == 3) {
      final leftPath = Path();
      final rightPath = Path();
      final bottomPath = Path();

      leftPath.addArc(
        Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius),
        -1.5708,
        3.14159,
      );
      leftPath.lineTo(pinCenterX, pinCenterY);
      leftPath.close();

      rightPath.addArc(
        Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinRadius),
        1.5708,
        3.14159,
      );
      rightPath.lineTo(pinCenterX, pinCenterY);
      rightPath.close();

      bottomPath.moveTo(pinCenterX - pinRadius * 0.3, triangleTopY);
      bottomPath.lineTo(pinCenterX + pinRadius * 0.3, triangleTopY);
      bottomPath.lineTo(pinCenterX, pinBottomY);
      bottomPath.close();

      Color leftColor;
      switch (bathroomTypes[0]) {
        case BathroomType.men:
          leftColor = menColor;
          break;
        case BathroomType.women:
          leftColor = womenColor;
          break;
        case BathroomType.other:
          leftColor = otherColor;
          break;
      }
      paint.color = leftColor;
      canvas.drawPath(leftPath, paint);

      Color rightColor;
      switch (bathroomTypes[1]) {
        case BathroomType.men:
          rightColor = menColor;
          break;
        case BathroomType.women:
          rightColor = womenColor;
          break;
        case BathroomType.other:
          rightColor = otherColor;
          break;
      }
      paint.color = rightColor;
      canvas.drawPath(rightPath, paint);

      Color bottomColor;
      switch (bathroomTypes[2]) {
        case BathroomType.men:
          bottomColor = menColor;
          break;
        case BathroomType.women:
          bottomColor = womenColor;
          break;
        case BathroomType.other:
          bottomColor = otherColor;
          break;
      }
      paint.color = bottomColor;
      canvas.drawPath(bottomPath, paint);
    }

    _drawToiletIcon(canvas, size);
  }

  void _drawToiletIcon(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final width = size.width;
    final pinRadius = width * 0.45;
    final pinCenterX = width / 2;
    final pinCenterY = pinRadius;

    final iconSize = pinRadius * 0.6;
    final centerX = pinCenterX;
    final centerY = pinCenterY;

    final seatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: iconSize * 0.8,
        height: iconSize * 0.4,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(seatRect, paint);

    final tankRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - iconSize * 0.2),
        width: iconSize * 0.6,
        height: iconSize * 0.3,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(tankRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BathroomPinPainter &&
        (oldDelegate.bathroomTypes != bathroomTypes ||
            oldDelegate.isSelected != isSelected);
  }
}
