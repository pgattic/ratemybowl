import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rate_my_bowl/widgets/bowl_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _logoController;
  late Animation<Alignment> _alignAnimation;
  late Animation<double> _sizeAnimation;

  bool _isVideoDone = false;
  bool _isLoading = true;
  bool _showLogo = false;
  bool _hasError = false;

  double _videoOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeLogoAnimation();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/splash_animation.mov');

      await _controller.initialize();

      // Load the SVG before animation finishes
      final loadSvg = SvgAssetLoader("assets/toilet.svg");
      await svg.cache.putIfAbsent(
        loadSvg.cacheKey(null),
        () => loadSvg.loadBytes(null),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Play the video
        await _controller.play();

        final videoDuration = _controller.value.duration;

        // Video start
        Future.delayed(videoDuration - const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _showLogo = true;
            _videoOpacity = 0.0;
          });
        });

        // Video finish
        Future.delayed(videoDuration, () {
          if (!mounted) return;
          setState(() => _isVideoDone = true);

          _startLogoSequence();
        });
      }
    } catch (e) {
      // If there's an error loading the video, show error and proceed after delay
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });

        // Wait a bit then proceed anyway
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onAnimationComplete();
          }
        });
      }
    }
  }

  void _initializeLogoAnimation() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _alignAnimation =
        AlignmentTween(
          begin: Alignment.center,
          end: const Alignment(0, -0.4),
        ).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
        );

    _sizeAnimation = Tween<double>(begin: 1.24, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  Future<void> _playLogoAnimation() async {
    if (mounted) {
      await _logoController.forward();
    }
  }

  Future<void> _startLogoSequence() async {
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 1));

    await _playLogoAnimation();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Stack(
        children: [
          // Background: either video or solid blue once finished
          Center(
            child: (_isVideoDone || _hasError)
                ? Container(
                    color: Colors.lightBlueAccent,
                  ) // solid background after video
                : _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading RateMyBowl',
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: AnimatedOpacity(
                      opacity: _videoOpacity,
                      duration: const Duration(seconds: 1),
                      child: VideoPlayer(_controller),
                    ),
                  ),
          ),
          // Logo animation overlay
          AnimatedOpacity(
            opacity: _showLogo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Align(
                  alignment: _alignAnimation.value,
                  child: Transform.scale(
                    scale: _sizeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const RateMyBowlLogo(),
            ),
          ),
        ],
      ),
    );
  }
}
