import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemontcg/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../data/tournament_locations.dart';
import 'debug_database_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _tournaments = [];
  bool _isLoading = true;
  String? _profileImagePath;
  String? _userTimezone;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTournaments();
  }

  Future<void> _loadUserData() async {
    final username = Provider.of<AuthProvider>(context, listen: false).username;
    if (username != null) {
      final user = await _db.getUser(username);
      if (mounted && user != null) {
        setState(() {
          _profileImagePath = user['profile_image'];
        });
      }
    }
  }

  Future<void> _loadTournaments() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      try {
        final tournaments = await _db.getUserTournaments(userId);
        final locationData = await LocationService.getCurrentLocation(context);

        if (mounted) {
          setState(() {
            _tournaments = tournaments;
            _userTimezone = locationData['timezone'] ?? 'UTC';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading tournaments: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTimezoneDisplay(String timezone) {
    String abbr;
    String? gmtOffset;

    // Get GMT offset
    try {
      final location = TimeService.getLocation(timezone);
      if (location != null) {
        final offset = location.currentTimeZone.offset ~/ 3600000;
        if (offset == 0) {
          gmtOffset = "GMT";
        } else {
          final sign = offset > 0 ? '+' : '';
          gmtOffset = "GMT$sign$offset";
        }
      }
    } catch (e) {
      print('Error getting timezone offset: $e');
    }

    // Get timezone abbreviation
    switch (timezone) {
      case 'Asia/Jakarta':
        abbr = 'WIB';
        break;
      case 'Asia/Makassar':
        abbr = 'WITA';
        break;
      case 'Asia/Jayapura':
        abbr = 'WIT';
        break;
      default:
        return gmtOffset ?? timezone.split('/').last.replaceAll('_', ' ');
    }

    // For Indonesian timezones, show both abbreviation and GMT offset
    return "$abbr (${gmtOffset ?? ''})";
  }

  String _getLocalTime(DateTime tournamentDate, String tournamentTimezone) {
    final format = DateFormat('EEEE, d MMMM y - HH:mm');
    final localTime = TimeService.convertTime(
      tournamentDate,
      fromTimezone: tournamentTimezone,
      toTimezone: _userTimezone ?? 'UTC',
    );
    return format.format(localTime);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final userId = Provider.of<AuthProvider>(context, listen: false).userId;
        if (userId != null) {
          await _db.updateUserProfileImage(userId, image.path);
          if (mounted) {
            setState(() {
              _profileImagePath = image.path;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRegistration(String tournamentName) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      try {
        await _db.cancelTournamentRegistration(userId, tournamentName);
        await _loadTournaments(); // Reload tournaments after cancellation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament registration cancelled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling registration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  TournamentLocation? _findTournamentLocation(String tournamentName) {
    try {
      return tournamentLocations.firstWhere(
        (location) => location.name == tournamentName,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<AuthProvider>(context).username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugDatabaseScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _profileImagePath != null
                                  ? FileImage(File(_profileImagePath!))
                                  : null,
                          child:
                              _profileImagePath == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadUserData();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final userId =
                              Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).userId?.toString() ??
                              '';
                          Navigator.pushNamed(context, '/purchase-history');
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Purchase History'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Registered Tournaments Section
            const Text(
              'Registered Tournaments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tournaments.isEmpty)
              const Center(
                child: Text(
                  'No tournaments registered yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tournaments.length,
                itemBuilder: (context, index) {
                  final tournament = _tournaments[index];
                  final tournamentDate = DateTime.parse(
                    tournament['tournament_date'],
                  );
                  final location = _findTournamentLocation(
                    tournament['tournament_name'],
                  );
                  final now = DateTime.now();
                  final isUpcoming = tournamentDate.isAfter(now);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(
                        Icons.emoji_events,
                        color: isUpcoming ? Colors.orange : Colors.grey,
                      ),
                      title: Text(tournament['tournament_name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tournament['tournament_location']),
                          if (location != null)
                            Text('Venue: ${location.venue}'),
                          Text(
                            'Tournament Time: ${DateFormat('EEEE, d MMMM y - HH:mm').format(tournamentDate)} ${_getTimezoneDisplay(location?.timezone ?? 'UTC')}',
                          ),
                          if (location != null)
                            Text(
                              'Local Time (${_getTimezoneDisplay(_userTimezone ?? 'UTC')}): ${_getLocalTime(tournamentDate, location.timezone)}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          Text(
                            'Status: ${tournament['status']}',
                            style: TextStyle(
                              color: isUpcoming ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                          isUpcoming
                              ? IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Cancel Registration',
                                          ),
                                          content: const Text(
                                            'Are you sure you want to cancel your registration for this tournament?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _cancelRegistration(
                                                  tournament['tournament_name'],
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Yes, Cancel'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              )
                              : null,
                      isThreeLine: true,
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'Teknologi Pemrograman Mobile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kesan:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Mata kuliah ini memberikan pengalaman belajar yang menarik dan sangat bermanfaat '
                    'untuk saya yang tertatrik memmamahami teknologi pemrograman mobile. Materi yang diberikan cukup lengkap '
                    'dan tugas yang menantang membuat pemahaman saya menjadi lebih mendalam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pesan:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Semoga mata kuliah ini terus mengikuti perkembangan teknologi mobile terbaru, '
                    'dan tetap memberikan studi kasus nyata agar mahasiswa lebih siap menghadapi '
                    'dunia industri. Terima kasih kepada bapak dosen yang telah membimbing saya dan teman-teman dengan baik.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
