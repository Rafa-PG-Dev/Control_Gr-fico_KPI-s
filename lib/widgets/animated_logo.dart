import 'package:flutter/material.dart';

class AnimatedLoginLogo extends StatefulWidget {
  final double width;
  final double height;

  const AnimatedLoginLogo({
    super.key,
    this.width = 280,
    this.height = 200,
  });

  @override
  State<AnimatedLoginLogo> createState() => _AnimatedLoginLogoState();
}

class _AnimatedLoginLogoState extends State<AnimatedLoginLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _loopController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _entryScaleAnimation;
  late final Animation<double> _loopRotation;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );


    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _entryScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

 
    _loopRotation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _pulseScale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _entryController.forward().whenComplete(() {
      _loopController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _loopController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.rotate(
            angle: _loopRotation.value,
            child: Transform.scale(
              scale: _entryScaleAnimation.value * _pulseScale.value,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/login_logo.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      ),
    );
  }
}
