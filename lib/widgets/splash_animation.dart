import 'package:flutter/material.dart';
import 'dart:math';

class SplashAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;

  const SplashAnimation({
    super.key,
    required this.width,
    required this.height,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final waterLevel = _controller.value * (widget.height + 150);

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _WaterPainter(waterLevel),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double waterLevel;
  double phaseX = 0;
  double t = 0;

  _WaterPainter(this.waterLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromARGB(255, 35, 200, 250);
    final path = Path();

    double waveHeight = 22;
    double waveLength = 0.03;
    double flowSpeed = 0.15;
    phaseX += flowSpeed;
    t += 0.02;

    double waveTopY = size.height - waterLevel;

    path.moveTo(0, size.height);
    path.lineTo(0, waveTopY);

    for (double x = -60; x <= size.width + 60; x += 1) {
      double baseWave = sin((x * waveLength) + phaseX) * waveHeight;
      path.lineTo(x, waveTopY + baseWave);
    }

    path.lineTo(size.width, waveTopY);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
