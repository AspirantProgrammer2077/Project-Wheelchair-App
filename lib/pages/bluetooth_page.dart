// ignore_for_file: prefer_final_fields, deprecated_member_use, unused_import, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wheelchair_app/pages/home_screen.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  bool _bluetoothEnabled = false;
  bool _isConnecting = false;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> _bondedDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStream;
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();

    // Listen for Bluetooth state changes
    _bluetoothStateSubscription =
        _bluetooth.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothEnabled = state == BluetoothState.STATE_ON;
        if (!_bluetoothEnabled) {
          _devices.clear();
          _bondedDevices.clear();
        }
      });
    });
  }

  @override
  void dispose() {
    _discoveryStream?.cancel();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  // Initialize Bluetooth
  Future<void> _initBluetooth() async {
    bool? enabled = await _bluetooth.isEnabled;
    setState(() => _bluetoothEnabled = enabled ?? false);

    if (_bluetoothEnabled) {
      await _requestPermissions();
      await _getBondedDevices(); // Get already paired devices
      _startScan();
    }
  }

  // Get bonded (paired) devices
  Future<void> _getBondedDevices() async {
    try {
      List<BluetoothDevice> bonded = await _bluetooth.getBondedDevices();
      setState(() {
        _bondedDevices = bonded;
      });
    } catch (e) {
      debugPrint("Error getting bonded devices: $e");
    }
  }

  // Request runtime permissions (Android 12+)
  Future<void> _requestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          statuses[Permission.location] != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bluetooth Scan and Location permissions are required."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Toggle Bluetooth On/Off
  Future<void> _toggleBluetooth(bool value) async {
  if (value) {
    // User wants to enable Bluetooth
    bool? enabled = await _bluetooth.requestEnable();
    if (enabled == true) {
      // Permissions + bonded devices + scan
      await _requestPermissions();
      await _getBondedDevices();
      _startScan();
      setState(() => _bluetoothEnabled = true);
    } else {
      setState(() => _bluetoothEnabled = false);
    }
  } else {
    // User wants to disable Bluetooth
    if (mounted) {
      // Show SnackBar to guide user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot disable Bluetooth programmatically.\nPlease turn it off in settings."
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );

      // Open Bluetooth settings
      await _bluetooth.openSettings();

      // Update the toggle to reflect actual state
      bool? isEnabled = await _bluetooth.isEnabled;
      setState(() {
        _bluetoothEnabled = isEnabled ?? false;
      });

      // Clear devices if Bluetooth is actually off
      if (_bluetoothEnabled == false) {
        _devices.clear();
        _bondedDevices.clear();
      }
    }
  }
}

  // Scan for devices
  void _startScan() {
    _devices.clear();

    _discoveryStream?.cancel();
    _discoveryStream = _bluetooth.startDiscovery().listen((result) {
      setState(() {
        final existingIndex =
            _devices.indexWhere((d) => d.address == result.device.address);
        if (existingIndex >= 0) {
          _devices[existingIndex] = result.device;
        } else {
          _devices.add(result.device);
        }
      });
    });

    _discoveryStream!.onDone(() {
      debugPrint("Discovery completed");
    });
  }

  // Check if device is bonded
  bool _isDeviceBonded(BluetoothDevice device) {
    return _bondedDevices.any((d) => d.address == device.address);
  }

  // Connect to a device with retry logic
  Future<void> _connect(BluetoothDevice device) async {
    // Check if device is bonded first
    if (!_isDeviceBonded(device)) {
      if (mounted) {
        final shouldPair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Device Not Paired'),
            content: Text(
              'The device "${device.name ?? 'Unknown'}" is not paired. '
              'Please pair it in your device\'s Bluetooth settings first, then try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldPair == true) {
          await _bluetooth.openSettings();
        }
      }
      return;
    }

    setState(() => _isConnecting = true);

    // Cancel discovery before connecting (important!)
    await _discoveryStream?.cancel();

    try {
      // Add a small delay to ensure discovery is fully stopped
      await Future.delayed(const Duration(milliseconds: 500));

      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      debugPrint("Connected successfully to ${device.name}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              bluetoothConnection: connection,
              connectedDevice: device,
              initialUsername: '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Connect error: $e");
      if (mounted) {
        setState(() => _isConnecting = false);
        
        // More user-friendly error messages
        String errorMessage = 'Failed to connect to device.';
        if (e.toString().contains('read failed')) {
          errorMessage = 'Connection failed. Please ensure:\n'
              '• The device is powered on\n'
              '• The device is in range\n'
              '• No other app is connected to it';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Device may be out of range or busy.';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connect(device); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isConnecting = false);
  }

  // UI
  @override
  Widget build(BuildContext context) {
    // Combine bonded and discovered devices, prioritizing bonded
    final allDevices = <BluetoothDevice>[
      ..._bondedDevices,
      ..._devices.where(
        (d) => !_bondedDevices.any((bonded) => bonded.address == d.address),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E22CE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bluetooth Control",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _bluetooth.openSettings(),
            tooltip: 'Bluetooth Settings',
          ),
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
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Bluetooth Toggle Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 3,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "Enable Bluetooth",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3C72),
                      ),
                    ),
                    value: _bluetoothEnabled,
                    onChanged: _toggleBluetooth,
                    activeColor: const Color(0xFF7E22CE),
                  ),
                ),
              ),

              // Scan Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _bluetoothEnabled ? _startScan : null,
                  icon: const Icon(Icons.search),
                  label: const Text("Scan Devices"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E22CE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Device List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          spreadRadius: 3,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: allDevices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled,
                                    size: 64,
                                    color: const Color(0xFF1E3C72).withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _bluetoothEnabled
                                        ? "No devices found\nTap 'Scan Devices' to search"
                                        : "Enable Bluetooth to scan for devices",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF1E3C72).withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: allDevices.length,
                              itemBuilder: (_, i) {
                                final d = allDevices[i];
                                final isBonded = _isDeviceBonded(d);
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBonded
                                        ? const Color(0xFF7E22CE).withOpacity(0.1)
                                        : const Color(0xFF2A5298).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isBonded
                                        ? Border.all(
                                            color: const Color(0xFF7E22CE).withOpacity(0.3),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
                                      color: const Color(0xFF7E22CE),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            d.name ?? "Unknown Device",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3C72),
                                            ),
                                          ),
                                        ),
                                        if (isBonded)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7E22CE),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'PAIRED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      d.address,
                                      style: TextStyle(
                                        color: const Color(0xFF1E3C72).withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: _isConnecting
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF7E22CE),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: () => _connect(d),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF7E22CE),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text("Connect"),
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}