// ignore_for_file: override_on_non_overriding_member, unused_import, deprecated_member_use, avoid_print, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:wheelchair_app/auth/auth_services.dart';
import 'package:wheelchair_app/pages/register_page.dart';
import 'package:wheelchair_app/pages/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Supabase
      await authService.signInwithEmailPassword(email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Color(0xFF7E22CE),
        ),
      );

      // Fetch username from Supabase user metadata safely
      String username = '';
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.userMetadata?.containsKey('username') ?? false) {
        username = user!.userMetadata!['username'] ?? '';
      }

      // Navigate to HomeScreen with username and remove previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(initialUsername: username),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      final message = e.message.isNotEmpty
          ? e.message
          : 'Login failed. Please check your email and password.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, st) {
      print('Unexpected login error: $e');
      print(st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error during login. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable back navigation from login page to prevent black screen
        return false;
      },
      child: Scaffold(
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
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7E22CE).withOpacity(0.3),
                                  spreadRadius: 4,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
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
                              ),
                              child: const Icon(
                                Icons.accessible,
                                size: 50,
                                color: Color(0xFF7E22CE),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to continue',
                          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureToggle: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password feature coming soon'),
                                backgroundColor: Color(0xFF2A5298),
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF7E22CE), Color(0xFF2A5298)],
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
                            onPressed: _isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                              child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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
      ),
    );
  }
}