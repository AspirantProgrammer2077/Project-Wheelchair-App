// ignore_for_file: unused_import

/*

AUTH GATE - CHECKS IF USER IS LOGGED IN OR NOT

unauthenticated -> Shows Login Page
authenticated -> Shows Home Page

*/

import 'package:flutter/material.dart';
import 'package:wheelchair_app/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelchair_app/pages/profile_page.dart';
import 'package:wheelchair_app/pages/register_page.dart'; 

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build appropriate page based on auth state
      builder: (context, snapshot) {
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        }
        // check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const ProfilePage();
        } else {
          return const LoginPage();
        }
      } 
        
    );

  }
}