
import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _itemController;
  late Animation<double> _item1Opacity;
  late Animation<double> _item2Opacity;
  late Animation<double> _item3Opacity;
  late Animation<double> _item1Translate;
  late Animation<double> _item2Translate;
  late Animation<double> _item3Translate;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );
    _itemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _item1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.25, 0.45)),
    );
    _item2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.5, 0.7)),
    );
    _item3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.75, 0.95)),
    );
    _item1Translate = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.25, 0.45)),
    );
    _item2Translate = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.5, 0.7)),
    );
    _item3Translate = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _itemController, curve: const Interval(0.75, 0.95)),
    );
    _logoController.forward();
    _itemController.repeat();
  }

  @override
  void dispose() {
  _logoController.dispose();
  _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFE0E7EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 192,
                height: 192,
                child: Stack(
                  children: [
                    // Animated Camera Icon
                    AnimatedBuilder(
                      animation: _itemController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _item1Opacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _item1Translate.value),
                            child: Align(
                              alignment: Alignment.center,
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuDmzub3vRBzmY2J0tJXaXZ6GPZEbOLZ2--CkJRo-TbRfRWfEkGRq1DedWZXsCdHySvW_eJvTxLVsUz9y8vkPC55LKnKNFmR7YrYfFDJWXZDvla965kH52Q5Ovq5HKU5QPr-waPoxUNyKL541rYaIoZz8fqLwUfVCaCLhf2odJ7di5Uit9OG7uukgcG1t-9BFRRdZW9tKXi0zvzzRwPsgZoOnLJrA5pkzjU9C2xboQfNzD_IenSoAQVk6fxVMZelnXSHTcYPnxkboNc',
                                width: 96,
                                height: 96,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated Drill Icon
                    AnimatedBuilder(
                      animation: _itemController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _item2Opacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _item2Translate.value),
                            child: Align(
                              alignment: Alignment.center,
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuAu2_AzyacHK2X9o3Q6Kq_XyrQBrqLTg_AsuSB0kfSqV_CR7kICL7meNtk-VqXwctvtMPfjrrkAKGnV5n8K5B4KBeUqSXNG6YLKHzRvQXhfdzgkLMWdigvx1fBWB00qWrXLJFTOc3VJzIqU6VCmknAtVZ1hLWOvu0RULDbdLe8kxZjA8Yv8rlU-CElCrI4-p4E0smQChbviBWVV1KszJ1ae0QCzts6MoI5UodZ1sQgUzLpqCAptKWUvj28CX6aP-8C_qylIFmXaa9w',
                                width: 96,
                                height: 96,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated Bicycle Icon
                    AnimatedBuilder(
                      animation: _itemController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _item3Opacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _item3Translate.value),
                            child: Align(
                              alignment: Alignment.center,
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuBI51Of-92x6AcVobnEcdM0mhA0sYJ7lDDHmNA3th-hYPo2QvGJiokw2nO6U1IPzR5KnMPShJ2X8GXEVqjnU2UUioWF4I9XsYuKqohp7z0ezF3aK0zpvzEzWPH3jCbng6WBRITWxzWUe2o-Xuc4J9hrdo0Aw6qxjG2uZGPrqlgVvZpFGoL0N1nq4viOkpWXdyPSoSA-oz6wsHPvSoOTq7nE4E-bdAQQS_dBbL3dXw1a91Z0qkLEdzgKTPc_416bhoilc1RbpkmI_Hc',
                                width: 96,
                                height: 96,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1990e6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.access_time,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Rentify',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                  letterSpacing: 1.5,
                  fontFamily: 'Plus Jakarta Sans',
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1990e6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
