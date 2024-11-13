import 'package:flutter/material.dart';
import 'package:photojam_app/main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animation controller for 2 seconds
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create fade animation that completes in the first third of 2 seconds
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.33, curve: Curves.easeIn),
      ),
    );

    // Scale with bounce effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.8, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOutBack)), // Bouncing in
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)), // Settling in
          weight: 30),
    ]).animate(_controller);

    // Rotation animation for a twist effect
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.12)
          .chain(CurveTween(curve: Curves.easeOut)), // Rotate to quarter turn
        weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 0.12, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)), // Rotate back to center
        weight: 50),
    ]).animate(_controller);

    // Color animation for background color transition
    _colorAnimation = ColorTween(
      begin: Color.fromARGB(255, 217, 197, 243),
      end: Color(0xFFF9D036),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation and navigate after resting for 1 second
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _controller.forward(); // Play animation over 2 seconds
    await Future.delayed(const Duration(seconds: 1)); // Rest for 1 second
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    }
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
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159, // Converting to radians
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/icon/app_icon_transparent.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}