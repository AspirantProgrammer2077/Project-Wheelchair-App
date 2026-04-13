// ignore_for_file: avoid_print, deprecated_member_use, unused_import, duplicate_import, depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelchair_app/auth/auth_services.dart';
import 'package:wheelchair_app/auth/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheelchair_app/pages/emergency_contacts_page.dart';
import 'package:wheelchair_app/pages/control_page.dart';
import 'package:wheelchair_app/pages/home_screen.dart';

class SettingsPage extends StatefulWidget {
  final BluetoothConnection? bluetoothConnection;
  final BluetoothDevice? connectedDevice;

  const SettingsPage({
    super.key,
    this.bluetoothConnection,
    this.connectedDevice,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 2;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _problemController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= NAV =================

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            bluetoothConnection: widget.bluetoothConnection,
            connectedDevice: widget.connectedDevice,
            initialUsername: '',
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ControlPage(
            bluetoothConnection: widget.bluetoothConnection,
            connectedDevice: widget.connectedDevice,
          ),
        ),
      );
    }
  }

  // ================= USERNAME =================

  void _editUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    String currentUsername =
        user.userMetadata?['username'] ?? prefs.getString('username') ?? '';

    _usernameController.text = currentUsername;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Enter new username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $currentUsername',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final newUsername = _usernameController.text.trim();
              if (newUsername.length < 3) return;

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'username': newUsername}),
                );

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', newUsername);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Username updated to "$newUsername"'),
                    backgroundColor: const Color(0xFF7E22CE),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(dialogContext);
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= PASSWORD =================

  void _changePassword() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _currentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              await Supabase.instance.client.auth.updateUser(
                UserAttributes(password: _newPasswordController.text.trim()),
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= REPORT =================

  void _reportProblem() {
    _problemController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report a Problem'),
        content: TextField(controller: _problemController, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            child: const Text('Send'),
            onPressed: () async {
              final subject = Uri.encodeComponent('Wheelchair App Problem');
              final body = Uri.encodeComponent(_problemController.text);
              final url = Uri.parse('mailto:andreidom907@gmail.com?subject=$subject&body=$body');
              await launchUrl(url);
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT =================

  void _logout() async {
    await authService.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  // ================= EMERGENCY =================

  void _openEmergencyContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsPage()),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(icon, size: 26, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF7E22CE),
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pan_tool_alt), label: 'Joystick'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF7E22CE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Settings', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingItem(icon: Icons.person, title: 'Edit Username', onTap: _editUsername),
                    _buildSettingItem(icon: Icons.lock, title: 'Change Password', onTap: _changePassword),
                    _buildSettingItem(icon: Icons.emergency, title: 'Emergency Contacts', onTap: _openEmergencyContacts),
                    _buildSettingItem(icon: Icons.flag, title: 'Report a Problem', onTap: _reportProblem),
                    _buildSettingItem(icon: Icons.logout, title: 'Log out', onTap: _logout),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}