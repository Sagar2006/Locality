import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Uncomment if you want to use custom SVG assets

class EnhancedSplashScreen extends StatefulWidget {
  const EnhancedSplashScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _itemsController;
  late AnimationController _backgroundController;
  late AnimationController _textController;
  late AnimationController _particlesController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoPulse;
  
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
    
    // Logo animations with pulse effect
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
    _logoPulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    
    // Floating items animations
    _itemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _itemsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: const Interval(0.2, 0.5, curve: Curves.easeIn)),
    );
    _itemsScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: const Interval(0.2, 0.6, curve: Curves.bounceOut)),
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
    
    // Particles controller
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    
    // Start animations in sequence
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _particlesController.repeat();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _itemsController.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });
    
    // Logo pulse effect after initial animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      _logoController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _itemsController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundController, _logoController, _itemsController, _textController, _particlesController]),
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
                // Enhanced background particles
                ..._buildBackgroundParticles(size),
                
                // Floating geometric shapes
                ..._buildFloatingShapes(size),
                
                // Main content
                SlideTransition(
                  position: _backgroundPosition,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced floating rental items around logo
                        SizedBox(
                          width: 350,
                          height: 350,
                          child: Stack(
                            children: [
                              // Central logo with pulse effect
                              Center(
                                child: Transform.scale(
                                  scale: _logoScale.value * _logoPulse.value,
                                  child: Transform.rotate(
                                    angle: _logoRotation.value * 0.1,
                                    child: Opacity(
                                      opacity: _logoOpacity.value,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          gradient: const RadialGradient(
                                            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF8e44ad)],
                                            stops: [0.0, 0.7, 1.0],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 25,
                                              offset: const Offset(0, 12),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF667eea).withOpacity(0.4),
                                              blurRadius: 50,
                                              offset: const Offset(0, 0),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFf093fb).withOpacity(0.3),
                                              blurRadius: 30,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Enhanced floating rental items
                              ..._buildEnhancedFloatingItems(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // App title with enhanced animation
                        Transform.scale(
                          scale: _titleScale.value,
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: Text(
                              'Locality',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3.0,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                  Shadow(
                                    color: const Color(0xFF667eea).withOpacity(0.5),
                                    blurRadius: 25,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Enhanced subtitle with slide animation
                        SlideTransition(
                          position: _subtitleSlide,
                          child: Opacity(
                            opacity: _subtitleOpacity.value,
                            child: const Text(
                              'Rent • Lend • Share',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                                letterSpacing: 1.5,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        SlideTransition(
                          position: _subtitleSlide,
                          child: Opacity(
                            opacity: _subtitleOpacity.value,
                            child: const Text(
                              'Your Amazon for Rentals',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white60,
                                letterSpacing: 1.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 70),
                        
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
                                width: 1,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
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

  List<Widget> _buildEnhancedFloatingItems() {
    const items = [
      {'icon': Icons.camera_alt, 'angle': 0.0, 'radius': 130.0, 'color': Color(0xFFFF6B6B)},
      {'icon': Icons.build, 'angle': 1.047, 'radius': 140.0, 'color': Color(0xFF4ECDC4)},
      {'icon': Icons.laptop, 'angle': 2.094, 'radius': 135.0, 'color': Color(0xFF45B7D1)},
      {'icon': Icons.sports_basketball, 'angle': 3.14159, 'radius': 130.0, 'color': Color(0xFFF39C12)},
      {'icon': Icons.music_note, 'angle': 4.189, 'radius': 145.0, 'color': Color(0xFF9B59B6)},
      {'icon': Icons.fitness_center, 'angle': 5.236, 'radius': 125.0, 'color': Color(0xFFE74C3C)},
      {'icon': Icons.kitchen, 'angle': 0.523, 'radius': 110.0, 'color': Color(0xFF2ECC71)},
      {'icon': Icons.travel_explore, 'angle': 3.665, 'radius': 115.0, 'color': Color(0xFFFF9500)},
    ];

    return items.map((item) {
      final angle = (item['angle'] as double) + (_itemsRotation.value * 0.3);
      final radius = item['radius'] as double;
      final icon = item['icon'] as IconData;
      final color = item['color'] as Color;

      final x = 175 + radius * cos(angle);
      final y = 175 + radius * sin(angle);

      return Positioned(
        left: x - 30,
        top: y - 30,
        child: Transform.scale(
          scale: _itemsScale.value,
          child: Opacity(
            opacity: _itemsOpacity.value,
            child: Transform.rotate(
              angle: -_itemsRotation.value * 0.5, // Counter-rotate for visual stability
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [color, color.withOpacity(0.8)],
                    stops: const [0.0, 1.0],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBackgroundParticles(Size size) {
    return List.generate(30, (index) {
      final random = Random(index);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final delay = random.nextDouble() * 3000;
      final speed = 0.5 + random.nextDouble() * 0.5;
      
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _particlesController,
          builder: (context, child) {
            final animationValue = ((_particlesController.value * speed) + delay / 3000) % 1.0;
            final opacity = (sin(animationValue * 2 * pi) * 0.4 + 0.2) * _backgroundOpacity.value;
            final scale = 0.5 + sin(animationValue * 2 * pi) * 0.3;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 3 + random.nextDouble() * 6,
                  height: 3 + random.nextDouble() * 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  List<Widget> _buildFloatingShapes(Size size) {
    final shapes = [
      {'x': size.width * 0.1, 'y': size.height * 0.2, 'size': 40.0, 'type': 'triangle'},
      {'x': size.width * 0.9, 'y': size.height * 0.3, 'size': 30.0, 'type': 'square'},
      {'x': size.width * 0.15, 'y': size.height * 0.8, 'size': 35.0, 'type': 'circle'},
      {'x': size.width * 0.85, 'y': size.height * 0.7, 'size': 25.0, 'type': 'diamond'},
    ];

    return shapes.map((shape) {
      return Positioned(
        left: shape['x'] as double,
        top: shape['y'] as double,
        child: AnimatedBuilder(
          animation: _particlesController,
          builder: (context, child) {
            final rotation = _particlesController.value * 2 * pi;
            final float = sin(_particlesController.value * 2 * pi) * 10;
            
            return Transform.translate(
              offset: Offset(0, float),
              child: Transform.rotate(
                angle: rotation * 0.2,
                child: Opacity(
                  opacity: 0.1 * _backgroundOpacity.value,
                  child: _buildShape(shape['type'] as String, shape['size'] as double),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildShape(String type, double size) {
    switch (type) {
      case 'triangle':
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(),
        );
      case 'square':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case 'diamond':
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
          ),
        );
      default: // circle
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}