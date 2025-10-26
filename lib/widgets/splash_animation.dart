import 'dart:math';
import 'dart:io' show Platform;
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
    this.speed = 1.5,
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
  double pouringStreamY = -200;
  bool pouringStreamDone = false;
  bool _soundPlayed = false;
  bool _isReadyToAnimate = false;

  @override
  void initState() {
    super.initState();
    _audio = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    WidgetsBinding.instance.deferFirstFrame();
    try {
      // Preload logo image
      await precacheImage(const AssetImage('assets/bowl_logo.png'), context);

      // Prepare sound
      await _audio.setPlayerMode(PlayerMode.mediaPlayer);
      await _audio.setReleaseMode(ReleaseMode.stop);
      await _audio.setVolume(Platform.isAndroid ? 1.0 : 0.7);
      await _audio.setSource(AssetSource('sounds/flush.mp3'));
      await _audio.stop();

      _controller = AnimationController(vsync: this, duration: widget.duration)
        ..addListener(_onAnimate);

      setState(() => _isReadyToAnimate = true);

      // Wait one full frame before animating to ensure GPU warmup
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        WidgetsBinding.instance.allowFirstFrame();
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) _controller.forward();
      });
    } catch (e) {
      debugPrint('Splash init error: $e');
      WidgetsBinding.instance.allowFirstFrame();
    }
  }

  void _onAnimate() {
    final progress = _controller.value;

    // Delay the pouring start a bit
    if (progress < 0.05) {
      pouringStreamY = -200;
    } else {
      if (!_soundPlayed) {
        _soundPlayed = true;
        _audio.resume();
      }

      pouringStreamY += 42 * widget.speed; // slightly faster
      if (pouringStreamY >= widget.height) {
        pouringStreamY = widget.height;
        pouringStreamDone = true;
      }
    }

    // Faster water rise
    if (pouringStreamDone) {
      // Changed from pow(progress, 1.5) to pow(progress, 1.1)
      // for a smoother, faster fill rate.
      final fill = pow(progress, 1.1);
      waterLevel = fill * (widget.height + 150);
      waterLevel = waterLevel.clamp(0.0, widget.height + 150);

      if (waterLevel >= widget.height) {
        _taperSound();
        widget.onFull();
      }
    }

    t += 0.03 * widget.speed;
    phaseX += 0.12 * widget.speed;

    if (mounted) setState(() {});
  }

  Future<void> _taperSound() async {
    const fadeDuration = Duration(milliseconds: 2000);
    const steps = 10;
    for (int i = 0; i < steps; i++) {
      await _audio.setVolume(
        (1 - i / steps) * (Platform.isAndroid ? 1.0 : 0.7),
      );
      await Future.delayed(
        Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps),
      );
    }
    await _audio.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading: white background + blue logo
    if (!_isReadyToAnimate) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: RateMyBowlLogo(textColor: Colors.lightBlueAccent),
        ),
      );
    }

    return Stack(
      children: [
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
        // ✅ Bring back logo fade-out as water rises
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: (waterLevel < widget.height / 2) ? 1.0 : 0.0,
            child: const RateMyBowlLogo(textColor: Colors.lightBlueAccent),
          ),
        ),
      ],
    );
  }
}

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

    // Background
    paint.color = waterLevel < size.height
        ? Colors.white
        : Colors.lightBlueAccent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Fade-in for wave visibility (smooth start)
    final fadeFactor = (waterLevel / (size.height * 0.4)).clamp(0.0, 1.0);

    // Water waves
    if (waterLevel > 0) {
      paint.color = Colors.lightBlueAccent.withOpacity(fadeFactor);
      final path = Path();
      final waveTopY = size.height - waterLevel;
      const waveHeight = 22.0;
      const waveLength = 0.03;

      path.moveTo(0, size.height);
      path.lineTo(0, waveTopY);
      for (double x = -60; x <= size.width + 60; x++) {
        final y = waveTopY + sin((x * waveLength) + phaseX) * waveHeight;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    // Pouring stream
    if (pouringStreamY > 0) {
      paint.color = Colors.lightBlueAccent;
      final path = Path();
      const swayAmount = 12.0;
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
  }

  @override
  bool shouldRepaint(_) => true;
}
