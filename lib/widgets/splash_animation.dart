import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:rate_my_bowl/widgets/bowl_logo.dart';

class SplashAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;
  final VoidCallback onFull;
  final double speed;

  const SplashAnimation({
    super.key,
    required this.width,
    required this.height,
    required this.onFull,
    this.duration = const Duration(seconds: 5),
    this.speed = 1.5, // Adjust the speed animation
  });

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AudioPlayer _audio;

  double waterLevel = 0;
  double t = 0;
  double phaseX = 0;
  double pouringStreamY = -100;
  bool pouringStreamDone = false;

  @override
  void initState() {
    super.initState();

    _audio = AudioPlayer();

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        final elapsed =
            _controller.value * widget.duration.inMilliseconds * widget.speed;

        // --- Pouring stream drops quickly to bottom
        if (!pouringStreamDone) {
          _audio.play(AssetSource('sounds/flush.mp3'));
          pouringStreamY += 36 * widget.speed;
          if (pouringStreamY >= widget.height) {
            pouringStreamY = widget.height;
            pouringStreamDone = true;
          }
        }

        // --- Fill water after stream reaches bottom
        if (pouringStreamDone) {
          final fillElapsed = elapsed;
          final progress = (fillElapsed / widget.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
          waterLevel = pow(progress, 1.5) * (widget.height + 150);
          waterLevel = waterLevel.clamp(0.0, widget.height + 150);

          if (waterLevel >= widget.height) widget.onFull();
        }

        // --- Animate wave phase
        t += 0.02 * widget.speed;
        phaseX += 0.15 * widget.speed;

        setState(() {});

        if (waterLevel >= widget.height) {
          _taperSound();
          widget.onFull();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _taperSound() async {
    const fadeDuration = Duration(milliseconds: 3000);
    const fadeSteps = 20;
    final fadeStepTime = fadeDuration.inMilliseconds ~/ fadeSteps;

    for (int i = 0; i < fadeSteps; i++) {
      final volume = 1.0 - (i / fadeSteps);
      await _audio.setVolume(volume);
      await Future.delayed(Duration(milliseconds: fadeStepTime));
    }

    await _audio.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Water and pouring stream
        CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _WaterPainter(
            waterLevel: waterLevel,
            t: t,
            phaseX: phaseX,
            pouringStreamY: pouringStreamY,
            pouringStreamDone: pouringStreamDone,
          ),
        ),

        // Blue logo overlay: disappears after water reaches half
        if (waterLevel < widget.height / 2)
          Center(
            child: const RateMyBowlLogo(textColor: Colors.lightBlueAccent),
          ),
      ],
    );
  }
}

/// Painter for water waves + pouring stream
class _WaterPainter extends CustomPainter {
  final double waterLevel;
  final double t;
  final double phaseX;
  final double pouringStreamY;
  final bool pouringStreamDone;

  _WaterPainter({
    required this.waterLevel,
    required this.t,
    required this.phaseX,
    required this.pouringStreamY,
    required this.pouringStreamDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Background: white until water fills, then blue
    paint.color = waterLevel < size.height
        ? Colors.white
        : Colors.lightBlueAccent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Flowing water surface
    if (waterLevel > 0) {
      paint.color = Colors.lightBlueAccent;
      final path = Path();
      final waveTopY = size.height - waterLevel;
      final waveHeight = 22.0;
      final waveLength = 0.03;

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

    // Pouring stream (wiggles side to side after reaching bottom)
    paint.color = Colors.lightBlueAccent;
    final path = Path();
    final swayAmount = 12.0;
    final sway = pouringStreamDone ? sin(t * 2) * swayAmount : 0.0;

    path.moveTo(size.width - 120, 0);
    path.cubicTo(
      size.width - 90 + sway,
      80,
      size.width - 140 + sway,
      200,
      size.width - 100 + sway,
      pouringStreamY,
    );
    path.lineTo(size.width - 80 + sway, pouringStreamY);
    path.cubicTo(
      size.width - 130 + sway,
      200,
      size.width - 70 + sway,
      80,
      size.width - 90 + sway,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
