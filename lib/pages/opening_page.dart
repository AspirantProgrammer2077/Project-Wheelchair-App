// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:wheelchair_app/pages/login_page.dart';
import 'package:wheelchair_app/pages/register_page.dart';

class OpeningPage extends StatefulWidget {
  const OpeningPage({super.key});

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72), // Deep navy blue
              Color(0xFF2A5298), // Medium blue
              Color(0xFF7E22CE), // Purple accent
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Animated Wheelchair Icon with Glow Effect
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(40.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  spreadRadius: 8,
                                  blurRadius: 30,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7E22CE).withOpacity(0.3),
                                  spreadRadius: 4,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(30.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.accessible,
                                size: 100,
                                color: Color(0xFF7E22CE),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // App Title with Fade Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Column(
                      children: [
                        Text(
                          'Project Wheelchair',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Smart Mobility Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Register Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildButton(
                      context: context,
                      label: 'Sign up',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      isPrimary: true,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Login Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildButton(
                      context: context,
                      label: 'Login',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      isPrimary: false,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF7E22CE),
                  Color(0xFF2A5298),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFF7E22CE).withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : const Color(0xFF1E3C72),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}