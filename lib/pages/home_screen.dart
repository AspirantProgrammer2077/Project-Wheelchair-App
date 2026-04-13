// ignore_for_file: avoid_print, deprecated_member_use, unused_import, unused_element, curly_braces_in_flow_control_structures, use_build_context_synchronously, unnecessary_brace_in_string_interps, unused_local_variable, non_constant_identifier_names, unnecessary_import, prefer_final_fields
import 'dart:async';
import 'dart:convert';
import 'dart:math' hide cos, asin;
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:wheelchair_app/pages/Bluetooth_page.dart';
import 'package:wheelchair_app/pages/chat_page.dart';
import 'package:wheelchair_app/pages/control_page.dart';
import 'package:wheelchair_app/services/weather_service.dart';
import 'package:wheelchair_app/models/weather_model.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheelchair_app/pages/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_telephony/telephony.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;



class HomeScreen extends StatefulWidget {
  final BluetoothConnection? bluetoothConnection;
  final BluetoothDevice? connectedDevice;
  final String initialUsername;

  const HomeScreen({
    super.key,
    this.bluetoothConnection,
    this.connectedDevice,
    required this.initialUsername,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // ===== CONFIRM SOS DIALOG =====
Future<void> _confirmSOS() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 32),
          SizedBox(width: 10),
          Text('Send SOS Alert?'),
        ],
      ),
      content: const Text(
        'This will send an emergency message with your location to all your emergency contacts.\n\nAre you sure?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('SEND SOS'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    _sendSOSMessage();
  }
}

  int _selectedIndex = 0;

  // Bluetooth
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  // Username
  late String _username;

  // Feature toggles
  bool _voiceControlEnabled = true;
  bool _weatherEnabled = true;
  bool _mapEnabled = true;
  bool _chatEnabled = true;

  // SOS Emergency
  bool _isSendingSOS = false;

  // Telephony (not used directly anymore for sendSms)
  final Telephony telephony = Telephony.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ControlPage(
            bluetoothConnection: _connection,
            connectedDevice: _connectedDevice,
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
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
          _selectedIndex = 0;
        });
        _loadFeatureToggles();
        _loadUsername();
      });
    }
  }

  // Weather
  final _weatherService = WeatherService('d6bfed16316fca5f6a270b39331d9c7f');
  Weather? _weather;

  // Layout constants
  final double horizontalPadding = 40.0;
  final double verticalPadding = 25.0;
  final double spacing = 20.0;

  // Speech-to-text
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isSpeechBusy = false;
  String _spokenText = '';
  String _lastCommand = '';
  DateTime? _lastListenTime;

  // Map & location
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  final List<LatLng> _pathPoints = [];
  


  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _connection = widget.bluetoothConnection;
    _connectedDevice = widget.connectedDevice;
    _isConnected = _connection != null;

    _username = widget.initialUsername;

    if (_connection != null) {
      _connection!.input?.listen((data) {
        final msg = utf8.decode(data);
        debugPrint("FROM ARDUINO: $msg");
      }).onDone(() {
        _disconnect();
      });
    }

    _loadUsername();
    _loadFeatureToggles();
    _getCurrentLocation();
    _fetchWeather();
  }

  @override
  void dispose() {
    _speech?.stop();
    _speech = null;
    _connection?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFeatureToggles();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? username;

      if (user != null) username = user.userMetadata?['username'];
      if (username == null || username.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        username = prefs.getString('username');
      }
      if (username == null || username.isEmpty) username = widget.initialUsername;

      if (mounted) {
        setState(() => _username = username!);
      }
    } catch (_) {
      if (mounted) setState(() => _username = widget.initialUsername);
    }
  }

  Future<void> _loadFeatureToggles() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _voiceControlEnabled = prefs.getBool('voiceControlEnabled') ?? true;
        _weatherEnabled = prefs.getBool('weatherEnabled') ?? true;
        _mapEnabled = prefs.getBool('mapEnabled') ?? true;
        _chatEnabled = prefs.getBool('chatEnabled') ?? true;
      });
    }
  }

  void _disconnect() {
    _connection?.dispose();
    if (mounted) {
      setState(() {
        _connection = null;
        _isConnected = false;
        _connectedDevice = null;
      });
    }
  }

  void _sendCommand(String cmd) {
    if (_connection != null && _isConnected) {
      try {
        _connection!.output.add(utf8.encode(cmd));
        _connection!.output.allSent;
        debugPrint("SENT TO ARDUINO: $cmd");
        if (mounted) _lastCommand = cmd;
      } catch (e) {
        debugPrint("Error sending command: $e");
      }
    } else {
      debugPrint("Not connected to Bluetooth device");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not connected to Bluetooth device'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _processVoiceCommand(String command) {
    String lowerCommand = command.toLowerCase().trim();
    if (!_isConnected || _connection == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth is not connected'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() => _spokenText = 'Bluetooth not connected');
      return;
    }

    if (lowerCommand.contains('forward') ||
        lowerCommand.contains('go') ||
        lowerCommand.contains('ahead') ||
        lowerCommand.contains('diretso') ||
        lowerCommand.contains('abante')) {
      _sendCommand('F');
      setState(() => _spokenText = 'Moving Forward');
    } else if (lowerCommand.contains('backward') ||
        lowerCommand.contains('back') ||
        lowerCommand.contains('reverse') ||
        lowerCommand.contains('atras')) {
      _sendCommand('B');
      setState(() => _spokenText = 'Moving Backward');
    } else if (lowerCommand.contains('left') ||
        lowerCommand.contains('turn left') ||
        lowerCommand.contains('kaliwa')) {
      _sendCommand('L');
      setState(() => _spokenText = 'Turning Left');
    } else if (lowerCommand.contains('right') ||
        lowerCommand.contains('turn right') ||
        lowerCommand.contains('kanan')) {
      _sendCommand('R');
      setState(() => _spokenText = 'Turning Right');
    } else if (lowerCommand.contains('stop') ||
        lowerCommand.contains('halt') ||
        lowerCommand.contains('wait') ||
        lowerCommand.contains('hinto')) {
      _sendCommand('S');
      setState(() => _spokenText = 'Stopped');
    } else {
      setState(() => _spokenText = 'Command not recognized: $command');
    }
  }

Future<void> _sendSOSMessage() async {
  try {
    if (_currentLocation == null) return;

    // Reverse geocode to get Address + Zip Code
    String locationString = 'Unknown area';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation!.latitude, 
        _currentLocation!.longitude
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        List<String> parts = [];
        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
        if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
        locationString = parts.join(', ');
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }

    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';

    // Build SOS message without map link
    final sosMessage = '''$_username needs help!
      Area: $locationString
      Time: $hour:$minute $amPm
      Respond ASAP!
      Press the Area Map Link to open Google Maps
      or Copy the Map Area and Search it in Google''';
      

    debugPrint('SOS Message:\n$sosMessage');
    await _sendSmsToContacts(sosMessage);

  } catch (e) {
    debugPrint('Error in _sendSOSMessage: $e');
  }
}
  
  Future<void> _fetchWeather() async {
    try {
      String cityName = await _weatherService.getCurrentCity();
      Weather weather = await _weatherService.getWeather(cityName);
      if (mounted) setState(() => _weather = weather);
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  String _getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'lib/assets/cloud.json';
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'lib/assets/cloud.json';
      case 'mist':
        return 'lib/assets/mist.json';
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'lib/assets/mist.json';
      case 'thunder':
      case 'thunderstorm':
        return 'lib/assets/thunder.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'lib/assets/rain.json';
      case 'clear':
        return 'lib/assets/sunny.json';
      default:
        return 'lib/assets/cloud.json';
    }
  }

  void _listen() async {
    if (!_voiceControlEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice control is disabled. Enable it in Settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_speech == null) {
      if (mounted) setState(() => _spokenText = 'Speech not initialized');
      return;
    }
    if (_lastListenTime != null &&
        DateTime.now().difference(_lastListenTime!).inSeconds < 2) {
      if (mounted) setState(() => _spokenText = 'Please kindly wait...');
      return;
    }
    if (_isListening || _isSpeechBusy) {
      await _speech!.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    _isSpeechBusy = true;
    _lastListenTime = DateTime.now();

    try {
      if (!_speech!.isAvailable) {
        bool available = await _speech!.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (error) {
            if (mounted) setState(() => _spokenText = 'Error: ${error.errorMsg}');
          },
        );
        if (!available) {
          if (mounted) setState(() => _spokenText = 'Speech not available');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_speech!.isListening) {
        await _speech!.stop();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) setState(() {
        _isListening = true;
        _spokenText = 'Listening...';
      });

      await _speech!.listen(
        partialResults: true,
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        onResult: (result) {
          if (mounted) setState(() => _spokenText = result.recognizedWords);
          if (result.finalResult) _processVoiceCommand(result.recognizedWords);
        },
        cancelOnError: true,
      );

      _isSpeechBusy = false;
    } catch (e) {
      if (mounted) setState(() {
        _isListening = false;
        _isSpeechBusy = false;
        _spokenText = 'Failed: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _pathPoints.add(_currentLocation!);
      }

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (mounted) {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _pathPoints.add(_currentLocation!);
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7E22CE),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3C72).withOpacity(0.05),
              const Color(0xFF7E22CE).withOpacity(0.1),
            ],
          ),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 16,
            maxZoom: 18,
            minZoom: 3,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wheelchair_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Color(0xFF7E22CE),
                    size: 50,
                  ),
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _pathPoints,
                  color: const Color(0xFF7E22CE),
                  strokeWidth: 4.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7E22CE),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A5298).withOpacity(0.2),
            const Color(0xFF7E22CE).withOpacity(0.15),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: Lottie.asset(
                _getWeatherAnimation(_weather?.mainCondition),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _weather?.cityName ?? 'Loading...',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3C72),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              '${_weather?.temperature.round()}°C',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E3C72),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              _weather?.mainCondition ?? '',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF1E3C72).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
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
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pan_tool_alt), label: 'Joystick'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      // ===== SOS FLOATING ACTION BUTTON =====
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _isSendingSOS ? null : _confirmSOS,
          backgroundColor: Colors.red,
          elevation: 8,
          child: _isSendingSOS
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(
                  Icons.sos,
                  size: 32,
                  color: Colors.white,
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF7E22CE)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            size: 40,
                            color: _isConnected ? const Color(0xFF7E22CE) : Colors.white,
                          ),
                          onPressed: () {
                            if (_isConnected) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Disconnect'),
                                  content: Text('Disconnect from ${_connectedDevice?.name ?? "device"}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _disconnect();
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const BluetoothPage()),
                                        );
                                      },
                                      child: const Text('Disconnect'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BluetoothPage()),
                              );
                            }
                          },
                        ),
                        if (_isConnected)
                          Text(
                            _connectedDevice?.name ?? 'Connected',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                    if (_chatEnabled)
                      IconButton(
                        icon: const Icon(Icons.android, size: 40, color: Colors.white70),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatPage()),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome User!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      _username,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Column(
                          children: [
                            if (_voiceControlEnabled) ...[
                              AspectRatio(
                                aspectRatio: 3 / 2,
                                child: WidgetTile(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF7E22CE).withOpacity(0.1),
                                          const Color(0xFF2A5298).withOpacity(0.15),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AvatarGlow(
                                          animate: _isListening,
                                          glowColor: const Color(0xFF7E22CE),
                                          duration: const Duration(milliseconds: 2000),
                                          repeat: true,
                                          child: IconButton(
                                            icon: Icon(
                                              _isListening ? Icons.mic : Icons.mic_none,
                                              size: 56,
                                              color: _isListening
                                                  ? const Color(0xFF7E22CE)
                                                  : const Color(0xFF1E3C72),
                                            ),
                                            onPressed: _listen,
                                          ),
                                        ),
                                        if (_lastCommand.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'Last: $_lastCommand',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF7E22CE).withOpacity(0.7),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _spokenText.isEmpty
                                    ? 'Say: Forward, Backward, Left, Right, Stop'
                                    : _spokenText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (_weatherEnabled)
                              AspectRatio(
                                aspectRatio: 3 / 3,
                                child: WidgetTile(
                                  child: _buildWeatherWidget(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (_mapEnabled)
                        Flexible(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: WidgetTile(
                              child: _buildMap(),
                            ),
                          ),
                        ),
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


// SEND SMS TO CONTACTS
Future<void> _sendSmsToContacts(String sosMessage) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? contactsJson = prefs.getStringList('emergency_contacts');

    if (contactsJson == null || contactsJson.isEmpty) {
      debugPrint('SOS Error: No emergency contacts found.');
      return;
    }

    final recipients = contactsJson.map((jsonStr) {
      final Map<String, dynamic> contact = jsonDecode(jsonStr);
      String phone = contact['phone'] as String;
      if (!phone.startsWith('+63')) phone = '+63$phone';
      return phone;
    }).toList();

    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:${recipients.join(";")}', // semicolon-separated
      arguments: <String, dynamic>{'sms_body': sosMessage}, // <-- use arguments
    );

    await intent.launch();
    debugPrint('SMS Intent launched to: ${recipients.join(", ")}');
  } catch (e) {
    debugPrint('Error sending SOS SMS: $e');
  }
}


class WidgetTile extends StatelessWidget {
  final Widget child;
  const WidgetTile({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 3, blurRadius: 12, offset: const Offset(0, 6)),
          BoxShadow(color: const Color(0xFF7E22CE).withOpacity(0.1), spreadRadius: -2, blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}


