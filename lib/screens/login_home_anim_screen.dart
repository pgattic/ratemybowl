import 'package:flutter/material.dart';
import 'package:rate_my_bowl/widgets/bowl_logo.dart';

class LoginHomeAnimLayer extends StatefulWidget {
  final Widget child; // LoginScreen or HomeScreen
  final bool isLoggedIn;

  const LoginHomeAnimLayer({
    super.key,
    required this.child,
    required this.isLoggedIn,
  });

  @override
  State<LoginHomeAnimLayer> createState() => _LoginHomeAnimLayerState();
}

class _LoginHomeAnimLayerState extends State<LoginHomeAnimLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // scale: 1.0 → 0.7
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // temporary slide animation to avoid LateInitializationError
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);

    // compute proper slide animation after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSlideAnimation();
      widget.isLoggedIn ? _controller.forward() : _controller.reverse();
    });
  }

  void _setupSlideAnimation() {
    final screenSize = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top + kToolbarHeight / 2;
    const paddingLeft = 16.0;

    // Start slightly above center
    final startDx = 0.0;
    final startDy = -2.66; // tweak as needed

    // Convert desired top-left position to relative Offset for SlideTransition
    final endDx =
        -(screenSize.width / 2 - paddingLeft - 128) / (screenSize.width / 2);
    final endDy =
        -(screenSize.height / 2 - paddingTop + 1580) / (screenSize.height / 2);

    _slideAnimation = Tween<Offset>(
      begin: Offset(startDx, startDy),
      end: Offset(endDx, endDy),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    setState(() {}); // rebuild to apply the new animation
  }

  @override
  void didUpdateWidget(covariant LoginHomeAnimLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoggedIn != widget.isLoggedIn) {
      widget.isLoggedIn ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // Login or Home underneath

        IgnorePointer(
          ignoring: true,
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  type: MaterialType
                      .transparency, // prevents bold/yellow underline
                  child: RateMyBowlLogo(
                    size: 1.0, // original size; will be scaled
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
