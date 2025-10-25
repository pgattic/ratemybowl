import 'package:flutter/material.dart';
import 'package:rate_my_bowl/widgets/bowl_logo.dart';
import 'package:rate_my_bowl/widgets/splash_animation.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Alignment> _alignAnimation;

  bool _showLogo = false;
  bool _waterFull = false;

  // Initialize
  @override
  void initState() {
    super.initState();
    _initializeLogoAnimation();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showLogo = true;
      });
    });
  }

  void _initializeLogoAnimation() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _alignAnimation =
        AlignmentTween(
          begin: Alignment.center,
          end: const Alignment(0, -0.395),
        ).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
        );
  }

  Future<void> _playLogoAnimation() async {
    if (mounted) await _logoController.forward();
  }

  Future<void> _startLogoSequence() async {
    await _playLogoAnimation();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _waterFull ? Colors.lightBlueAccent : Colors.white,
      body: Stack(
        children: [
          // Water animation
          Positioned.fill(
            child: SplashAnimation(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              onFull: () {
                if (!mounted) return;
                setState(() => _waterFull = true);
                _startLogoSequence();
              },
            ),
          ),

          // Logo
          AnimatedOpacity(
            opacity: _showLogo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1500),
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Align(alignment: _alignAnimation.value, child: child);
              },
              child: const RateMyBowlLogo(),
            ),
          ),
        ],
      ),
    );
  }
}
