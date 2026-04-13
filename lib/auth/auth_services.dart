// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? getCurrentUser() => _supabase.auth.currentUser;

  // Sign in with email and password
  Future<AuthResponse> signInwithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password (no manual profiles insert)
  Future<AuthResponse> signUpwithEmailPassword(String email, String password, {required String username}) async {
  return await _supabase.auth.signUp(
    email: email,
    password: password,
    data: {
      'username': username,
      },
    );
  }

  // Update username in Supabase (after signup)
  Future<void> updateUsername(String userId, String username) async {
    await _supabase.from('profiles').update({
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Get username from Supabase
  Future<String?> getUsername(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();
      return response['username'] as String?;
    } catch (e) {
      print('Error fetching username: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  getCurrentUserEmail() {}
}
