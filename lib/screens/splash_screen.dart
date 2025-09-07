
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _courierController;
  late AnimationController _packageController;
  late AnimationController _backgroundController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _courierPosition;
  late Animation<double> _courierOpacity;
  late Animation<double> _packageScale;
  late Animation<double> _packageRotation;
  late Animation<Offset> _packagePosition;
  late Animation<double> _backgroundScale;
  late Animation<double> _titleOpacity;
  late Animation<double> _titleScale;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Courier delivery animation
    _courierController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _courierPosition = Tween<double>(begin: -200, end: 100).animate(
      CurvedAnimation(parent: _courierController, curve: Curves.easeInOut),
    );

    _courierOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _courierController, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    // Package delivery animation
    _packageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _packageScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _packageController, curve: const Interval(0.2, 0.5, curve: Curves.elasticOut)),
    );

    _packageRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _packageController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );

    _packagePosition = Tween<Offset>(begin: const Offset(0, -100), end: Offset.zero).animate(
      CurvedAnimation(parent: _packageController, curve: const Interval(0.2, 0.7, curve: Curves.bounceOut)),
    );

    // Background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _backgroundScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _titleScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 0.8, curve: Curves.elasticOut)),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.6, 0.9, curve: Curves.easeIn)),
    );

    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    // Pulse animation for delivery icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations in sequence
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _courierController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _packageController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      _pulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _courierController.dispose();
    _packageController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _courierController,
          _packageController,
          _backgroundController,
          _textController,
          _pulseController
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.9),
                  const Color(0xFF764ba2).withOpacity(0.9),
                  const Color(0xFFF093FB).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background elements
                ..._buildDeliveryElements(size),

                // Main delivery scene
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Courier and Package Scene
                      SizedBox(
                        width: 300,
                        height: 250,
                        child: Stack(
                          children: [
                            // Courier (animated from left)
                            Positioned(
                              left: _courierPosition.value,
                              top: 80,
                              child: Opacity(
                                opacity: _courierOpacity.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delivery_dining,
                                    size: 40,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                              ),
                            ),

                            // Delivery Package (animated from top)
                            Positioned(
                              right: 50,
                              top: 60,
                              child: SlideTransition(
                                position: _packagePosition,
                                child: Transform.scale(
                                  scale: _packageScale.value,
                                  child: Transform.rotate(
                                    angle: _packageRotation.value,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B6B),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Pulsing delivery icon in center
                            Positioned(
                              left: 110,
                              top: 100,
                              child: Transform.scale(
                                scale: _pulseScale.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF667eea).withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App title with dramatic animation
                      Transform.scale(
                        scale: _titleScale.value,
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: const Text(
                            'Locality',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3.0,
                              fontFamily: 'Poppins',
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                ),
                                Shadow(
                                  color: Color(0xFF667eea).withOpacity(0.5),
                                  blurRadius: 25,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle with slide animation
                      SlideTransition(
                        position: _subtitleSlide,
                        child: Opacity(
                          opacity: _subtitleOpacity.value,
                          child: const Text(
                            'Your Local Marketplace',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SlideTransition(
                        position: _subtitleSlide,
                        child: Opacity(
                          opacity: _subtitleOpacity.value,
                          child: const Text(
                            'Lend • Borrow • Deliver',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 1.0,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Enhanced loading indicator
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDeliveryElements(Size size) {
    return [
      // Floating delivery trucks
      Positioned(
        left: 50,
        top: 100,
        child: AnimatedBuilder(
          animation: _courierController,
          builder: (context, child) {
            return Opacity(
              opacity: _courierOpacity.value * 0.3,
              child: Transform.rotate(
                angle: _courierController.value * 0.1,
                child: const Icon(
                  Icons.local_shipping,
                  size: 40,
                  color: Colors.white24,
                ),
              ),
            );
          },
        ),
      ),

      // Floating packages
      Positioned(
        right: 80,
        top: 150,
        child: AnimatedBuilder(
          animation: _packageController,
          builder: (context, child) {
            return Opacity(
              opacity: _packageController.value * 0.4,
              child: Transform.scale(
                scale: 0.8 + (_packageController.value * 0.2),
                child: const Icon(
                  Icons.inventory_2,
                  size: 30,
                  color: Colors.white30,
                ),
              ),
            );
          },
        ),
      ),

      // Delivery route lines
      Positioned(
        left: 0,
        right: 0,
        top: size.height * 0.6,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Opacity(
              opacity: _backgroundController.value * 0.2,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Animated dots representing delivery points
      ...List.generate(5, (index) {
        final random = Random(index);
        return Positioned(
          left: random.nextDouble() * size.width,
          top: random.nextDouble() * size.height,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: (sin(_pulseController.value * 2 * pi + index) * 0.3 + 0.2) * _backgroundController.value,
                child: Container(
                  width: 6 + random.nextDouble() * 4,
                  height: 6 + random.nextDouble() * 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    ];
  }
}
}
