// emergency_contacts_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<Map<String, String>> _emergencyContacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList('emergency_contacts') ?? [];

    setState(() {
      _emergencyContacts = contactsJson
          .map((json) => Map<String, String>.from(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = _emergencyContacts
        .map((contact) => jsonEncode(contact))
        .toList();

    await prefs.setStringList('emergency_contacts', contactsJson);
  }

  void _addContact() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _emergencyContacts.add({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });
    });

    _saveEmergencyContacts();

    _nameController.clear();
    _phoneController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency contact added'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _saveEmergencyContacts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency contact removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Mom, Dad, Caregiver',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., +639123456789',
                border: OutlineInputBorder(),
                prefixText: '+63 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Format: 9123456789 (without +63)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _phoneController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addContact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E22CE),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E22CE),
        elevation: 0,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
              // Info Card
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF7E22CE),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Emergency SOS Feature',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3C72),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Press the red SOS button on the home screen to send an emergency message with your location to all contacts below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contact List
              Expanded(
                child: _emergencyContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Emergency Contacts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap + to add your first contact',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _emergencyContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _emergencyContacts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF7E22CE),
                                child: Text(
                                  contact['name']![0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                contact['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '+63${contact['phone']}',
                                style: TextStyle(
                                  color: const Color(0xFF1E3C72).withOpacity(0.7),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeContact(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: const Color(0xFF7E22CE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}