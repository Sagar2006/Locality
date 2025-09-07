
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _itemsController;
  late AnimationController _backgroundController;
  late AnimationController _textController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  
  late Animation<double> _itemsOpacity;
  late Animation<double> _itemsScale;
  late Animation<double> _itemsRotation;
  
  late Animation<double> _backgroundOpacity;
  late Animation<Offset> _backgroundPosition;
  
  late Animation<double> _titleOpacity;
  late Animation<double> _titleScale;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  @override
  void initState() {
    super.initState();
    
    // Logo animations
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    
    // Floating items animations
    _itemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _itemsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    _itemsScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: const Interval(0.3, 0.8, curve: Curves.bounceOut)),
    );
    _itemsRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _itemsController, curve: Curves.linear),
    );
    
    // Background animations
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeIn),
    );
    _backgroundPosition = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );
    
    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );
    _titleScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 0.8, curve: Curves.elasticOut)),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.6, 0.9, curve: Curves.easeIn)),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    
    // Start animations in sequence
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _itemsController.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _itemsController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundController, _logoController, _itemsController, _textController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(_backgroundOpacity.value),
                  const Color(0xFF764ba2).withOpacity(_backgroundOpacity.value),
                  const Color(0xFFf093fb).withOpacity(_backgroundOpacity.value * 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ..._buildBackgroundParticles(size),
                
                // Main content
                SlideTransition(
                  position: _backgroundPosition,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Floating rental items around logo
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: Stack(
                            children: [
                              // Central logo
                              Center(
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Transform.rotate(
                                    angle: _logoRotation.value * 0.1, // Gentle rotation
                                    child: Opacity(
                                      opacity: _logoOpacity.value,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                              blurRadius: 40,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Floating rental items
                              ..._buildFloatingItems(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // App title with animation
                        Transform.scale(
                          scale: _titleScale.value,
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: const Text(
                              'Locality',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2.0,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
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
                              'Rent • Lend • Share',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                letterSpacing: 1.2,
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
                              'Your Amazon for Rentals',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white60,
                                letterSpacing: 0.8,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Loading indicator with custom styling
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingItems() {
    const items = [
      {'icon': Icons.camera_alt, 'angle': 0.0, 'radius': 100.0, 'color': Color(0xFFFF6B6B)},
      {'icon': Icons.build, 'angle': 1.047, 'radius': 110.0, 'color': Color(0xFF4ECDC4)}, // 60 degrees
      {'icon': Icons.laptop, 'angle': 2.094, 'radius': 105.0, 'color': Color(0xFF45B7D1)}, // 120 degrees
      {'icon': Icons.sports_basketball, 'angle': 3.14159, 'radius': 100.0, 'color': Color(0xFFF39C12)}, // 180 degrees
      {'icon': Icons.music_note, 'angle': 4.189, 'radius': 115.0, 'color': Color(0xFF9B59B6)}, // 240 degrees
      {'icon': Icons.fitness_center, 'angle': 5.236, 'radius': 95.0, 'color': Color(0xFFE74C3C)}, // 300 degrees
    ];

    return items.map((item) {
      final angle = (item['angle'] as double) + (_itemsRotation.value * 0.5);
      final radius = item['radius'] as double;
      final icon = item['icon'] as IconData;
      final color = item['color'] as Color;

      final x = 150 + radius * cos(angle);
      final y = 150 + radius * sin(angle);

      return Positioned(
        left: x - 25,
        top: y - 25,
        child: Transform.scale(
          scale: _itemsScale.value,
          child: Opacity(
            opacity: _itemsOpacity.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBackgroundParticles(Size size) {
    return List.generate(20, (index) {
      final random = Random(index);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final delay = random.nextDouble() * 2000;
      
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _itemsController,
          builder: (context, child) {
            final animationValue = (_itemsController.value + delay / 2000) % 1.0;
            return Opacity(
              opacity: (sin(animationValue * 2 * pi) * 0.3 + 0.1) * _backgroundOpacity.value,
              child: Container(
                width: 4 + random.nextDouble() * 8,
                height: 4 + random.nextDouble() * 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
}
