import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemontcg/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class TournamentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentRegistrationScreen({super.key, required this.tournament});

  @override
  State<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends State<TournamentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _db = DatabaseHelper();
  bool _isLoading = false;
  String _localTime = '';
  String _gmtTime = '';
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTimes();
    _checkRegistrationStatus();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _checkRegistrationStatus() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      final isRegistered = await _db.isUserRegisteredForTournament(
        userId,
        widget.tournament['name'],
      );
      if (mounted) {
        setState(() {
          _isRegistered = isRegistered;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final username = Provider.of<AuthProvider>(context, listen: false).username;
    if (username != null) {
      final user = await _db.getUser(username);
      if (mounted && user != null) {
        setState(() {
          _fullNameController.text = user['full_name'] ?? '';
          _countryController.text = user['country'] ?? '';
          _cityController.text = user['city'] ?? '';
        });
      }
    }
  }

  Future<void> _loadTimes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get local time for the tournament timezone
      final localTimeResponse = await http.get(
        Uri.parse(
          '${dotenv.env['TIME_API_BASE_URL']}/time/current/zone?timeZone=${widget.tournament['timezone']}',
        ),
      );

      if (!mounted) return;

      if (localTimeResponse.statusCode == 200) {
        final localTimeData = json.decode(localTimeResponse.body);
        if (!mounted) return;
        setState(() {
          _localTime =
              '${localTimeData['time']} ${widget.tournament['timezone']}';
        });
      }

      // Get GMT time
      final gmtResponse = await http.get(
        Uri.parse(
          '${dotenv.env['TIME_API_BASE_URL']}/time/current/zone?timeZone=GMT',
        ),
      );

      if (!mounted) return;

      if (gmtResponse.statusCode == 200) {
        final gmtData = json.decode(gmtResponse.body);
        if (!mounted) return;
        setState(() {
          _gmtTime = '${gmtData['time']} GMT';
        });
      }
    } catch (e) {
      print('Error loading times: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).userId;
        if (userId != null) {
          // Update user info
          await _db.updateUser(userId, {
            'full_name': _fullNameController.text,
            'age': int.parse(_ageController.text),
            'country': _countryController.text,
            'city': _cityController.text,
          });

          // Save tournament registration
          await _db.registerTournament({
            'user_id': userId,
            'tournament_name': widget.tournament['name'],
            'tournament_location': widget.tournament['location'],
            'tournament_date': widget.tournament['date'],
            'status': 'registered',
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<AuthProvider>(context).username;
    final tournamentDate = DateTime.parse(widget.tournament['date']);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Info
              Text(
                widget.tournament['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tournament['location'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tournament Date: ${DateFormat('EEEE, d MMMM y - HH:mm').format(tournamentDate)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Time Information
              const Text(
                'Time Information:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text('Local Time: $_localTime'),
                Text('GMT: $_gmtTime'),
              ],
              const SizedBox(height: 24),

              if (_isRegistered)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are already registered for this tournament!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Registration Form
                const Text(
                  'Registration Form:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: false,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 13) {
                      return 'You must be at least 13 years old';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Submit Registration'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
