// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:wheelchair_app/pages/caregiver_page.dart';
import 'package:wheelchair_app/pages/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelchair_app/pages/opening_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    anonKey: 'PLACE YOUR ANONKEY FROM YOUR SUPABASE PROJECT',
    url: 'PLACE YOUR URL FROM YOUR SUPABASE PROJECT',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wheelchair App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// Auth Gate - Handles authentication state and navigation
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      
      if (mounted) {
        if (session != null) {
          // User logged in
          _navigateToHome();
        } else {
          // User logged out
          _navigateToOpening();
        }
      }
    });
  }

  void _navigateToHome() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final username = user.userMetadata?['username'] ?? 'User';
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            bluetoothConnection: null,
            connectedDevice: null,
            initialUsername: username,
          ),
        ),
      );
    }
  }

  void _navigateToOpening() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OpeningPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check current session
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // User is logged in, show HomeScreen
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['username'] ?? 'User';
      
      return HomeScreen(
        bluetoothConnection: null,
        connectedDevice: null,
        initialUsername: username,
      );
    } else {
      // User is not logged in, show OpeningPage
      return const OpeningPage();
    }
  }
}
