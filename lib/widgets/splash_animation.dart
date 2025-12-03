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
    // Prevent first frame until we're ready
    WidgetsBinding.instance.deferFirstFrame();

    try {
      // Prepare audio
      await _audio.setPlayerMode(PlayerMode.mediaPlayer);
      await _audio.setReleaseMode(ReleaseMode.stop);
      await _audio.setVolume(Platform.isAndroid ? 1.0 : 0.7);

      // Load audio asset but don't play yet
      await _audio.setSource(AssetSource('sounds/flush.mp3'));

      // Mark ready
      setState(() => _isReadyToAnimate = true);

      // Allow first frame and start animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.allowFirstFrame();
        _startAnimation();
      });
    } catch (e) {
      debugPrint('Splash init error: $e');
      WidgetsBinding.instance.allowFirstFrame();
    }
  }

  void _startAnimation() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onAnimate);

    if (mounted) _controller.forward();
  }

  void _onAnimate() {
    final progress = _controller.value;

    // Delay pouring start
    if (progress < 0.05) {
      pouringStreamY = -200;
    } else {
      if (!_soundPlayed && _audio.state == PlayerState.stopped) {
        _soundPlayed = true;
        try {
          _audio.resume();
        } catch (e) {
          debugPrint('Audio resume failed: $e');
        }
      }

      pouringStreamY += 42 * widget.speed;
      if (pouringStreamY >= widget.height) {
        pouringStreamY = widget.height;
        pouringStreamDone = true;
      }
    }

    if (pouringStreamDone) {
      final fill = pow(progress, 1.1);
      waterLevel = (fill * (widget.height + 150)).clamp(
        0.0,
        widget.height + 150,
      );

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
    if (!mounted) return; // Make sure widget still exists
    if (_audio.state == PlayerState.disposed) return;

    const fadeDuration = Duration(milliseconds: 2000);
    const steps = 10;

    for (int i = 0; i < steps; i++) {
      if (!mounted || _audio.state == PlayerState.disposed) break;

      try {
        await _audio.setVolume(
          (1 - i / steps) * (Platform.isAndroid ? 1.0 : 0.7),
        );
      } catch (e) {
        debugPrint('Audio setVolume failed: $e');
        break;
      }

      await Future.delayed(
        Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps),
      );
    }

    if (mounted && _audio.state != PlayerState.disposed) {
      try {
        await _audio.stop();
      } catch (e) {
        debugPrint('Audio stop failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until audio/logo ready
    if (!_isReadyToAnimate) {
      return Container(
        //color: Colors.white,
        child: const Center(
          child: RateMyBowlLogo(color: Colors.lightBlueAccent),
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
        Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: (waterLevel < widget.height / 2) ? 1.0 : 0.0,
            child: const RateMyBowlLogo(color: Colors.lightBlueAccent),
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
