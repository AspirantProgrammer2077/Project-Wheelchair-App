// ignore_for_file: unused_import, deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:wheelchair_app/pages/settings_page.dart';

class ControlPage extends StatefulWidget {
  final BluetoothConnection? bluetoothConnection;
  final BluetoothDevice? connectedDevice;

  const ControlPage({
    super.key,
    this.bluetoothConnection,
    this.connectedDevice,
  });

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  int _selectedIndex = 1;
  String _selectedSpeed = 'Medium';

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  // === Anti spam ===
  String _lastCmd = '';
  DateTime _lastSend = DateTime.now();

  @override
  void initState() {
    super.initState();
    _connection = widget.bluetoothConnection;
    _connectedDevice = widget.connectedDevice;
    _isConnected = _connection != null;
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      await Future.delayed(const Duration(milliseconds: 150));
      Navigator.pop(context);
    } else if (index == 2) {
      await Future.delayed(const Duration(milliseconds: 150));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            bluetoothConnection: _connection,
            connectedDevice: _connectedDevice,
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 1;
        });
      });
    }
  }

  // ===== SEND TO ARDUINO =====
  void _sendCommand(String cmd) {
    if (_connection != null && _isConnected) {
      final now = DateTime.now();

      if (cmd != _lastCmd || now.difference(_lastSend).inMilliseconds > 120) {
        _lastCmd = cmd;
        _lastSend = now;

        _connection!.output.add(utf8.encode(cmd));
        _connection!.output.allSent;
        debugPrint("SENT: $cmd");
      }
    }
  }

 // ===== JOYSTICK BRIDGE =====
// Converts joystick X/Y movement into single-character commands
// that are sent to Arduino for wheelchair control.
void _handleJoystickMovement(double x, double y) {
  // Deadzone threshold to avoid sending commands for small movements
  const double threshold = 0.3;

  // Default command: 'K' means STOP / IDLE
  String cmd = 'K';

  // If joystick is near the center, stop the wheelchair
  if (y.abs() < threshold && x.abs() < threshold) {
    cmd = 'K';
  } 
  // Forward movement
  else if (y > threshold && x.abs() < threshold) {
    cmd = 'H';
  } 
  // Backward movement
  else if (y < -threshold && x.abs() < threshold) {
    cmd = 'G';
  } 
  // Turn left
  else if (x < -threshold && y.abs() < threshold) {
    cmd = 'I';
  } 
  // Turn right
  else if (x > threshold && y.abs() < threshold) {
    cmd = 'J';
  }

  // Send the computed command to Arduino via Bluetooth
  _sendCommand(cmd);
}

  final double horizontalPadding = 40.0;
  final double verticalPadding = 25.0;

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
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pan_tool_alt), label: 'Joystick'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                if (_isConnected)
                  Text(
                    'Connected: ${_connectedDevice?.name ?? "Device"}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    'Not Connected',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 20),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSpeedButton('Low'),
                    _buildSpeedButton('Medium'),
                    _buildSpeedButton('Fast'),
                  ],
                ),

                const SizedBox(height: 40),

                Expanded(
                  child: Center(
                    child: Joystick(
                      mode: JoystickMode.all,
                      listener: (details) {
                        _handleJoystickMovement(details.x, details.y);
                      },
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

  Widget _buildSpeedButton(String speed) {
    bool isSelected = _selectedSpeed == speed;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSpeed = speed;
        });

        if (speed == 'Low') _sendCommand('X');
        if (speed == 'Medium') _sendCommand('Y');
        if (speed == 'Fast') _sendCommand('Z');
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7E22CE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          speed,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
