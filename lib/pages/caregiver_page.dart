// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverPage extends StatefulWidget {
  final String initialUsername;

  const CaregiverPage({
    super.key,
    required this.initialUsername,
  });

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  late String _username;

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  final List<LatLng> _pathPoints = [];

  final double horizontalPadding = 40.0;
  final double verticalPadding = 25.0;

  @override
  void initState() {
    super.initState();
    _username = widget.initialUsername;
    _loadUsername();
    _getCurrentLocation();
  }

  Future<void> _loadUsername() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? username = user?.userMetadata?['username'];

      if (mounted) {
        setState(() {
          _username = username?.isNotEmpty == true ? username! : widget.initialUsername;
        });
      }
    } catch (e) {
      print('Username load error: $e');
      setState(() => _username = widget.initialUsername);
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
      print('Location error: $e');
    }
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7E22CE)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation!,
          initialZoom: 16,
          maxZoom: 18,
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
                strokeWidth: 4,
              ),
            ],
          ),
        ],
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
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking Patient',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
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
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 3,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: _buildMap(),
                    ),
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
