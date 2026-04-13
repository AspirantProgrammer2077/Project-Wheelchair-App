// ignore_for_file: non_constant_identifier_names, deprecated_member_use, unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:wheelchair_app/auth/auth_services.dart';
import 'package:wheelchair_app/pages/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // get auth service
  final authService = AuthService();

  // text controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // loading state
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Save username to shared preferences (as backup/cache)
  Future<void> _saveUsernameLocally(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // sign up button pressed
  void SignUp() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // prepare data
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check username length
    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 3 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // check that passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords don\'t match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // attempt sign up...
    try {
      // Sign up with email, password, AND username (stored in Supabase)
      await authService.signUpwithEmailPassword(
        email,
        password,
        username: username,
      );

      // Also save username locally as a cache
      await _saveUsernameLocally(username);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Check your email to verify your account.',
          ),
          backgroundColor: Color(0xFF7E22CE),
          duration: Duration(seconds: 2),
        ),
      );

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Use pushAndRemoveUntil to prevent going back to registration
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialUsername: '',),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;

      String message = 'Sign up failed. Please try again.';

      // Handle Supabase 60s email rate limit
      if (e.code == 'over_email_send_rate_limit') {
        message =
            'You can only request a new confirmation email once every 60 seconds. Please wait a moment, then try again.';
      } else if (e.message.isNotEmpty) {
        // Fall back to Supabase’s own message if available
        message = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, stackTrace) {
  print('=== SIGNUP ERROR ===');
  print('Error: $e');
  print('Stack trace: $stackTrace');
  print('===================');
  
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Unexpected error during sign up: $e',
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ),
  );
    }
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool? obscureToggle,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureToggle ?? obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF1E3C72),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFF1E3C72).withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF7E22CE),
          ),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscureToggle! ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF7E22CE).withOpacity(0.7),
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(
              color: Color(0xFF7E22CE),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
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
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF7E22CE),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),

                      // Welcome Text
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // Username Field
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureToggle: _obscurePassword,
                        onToggleObscure: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureToggle: _obscureConfirmPassword,
                        onToggleObscure: () {
                          setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // Password Requirements
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Username must be at least 3 characters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '• Password must be at least 6 characters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign Up Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF7E22CE),
                              Color(0xFF2A5298),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7E22CE).withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : SignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}