import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DebugDatabaseScreen extends StatefulWidget {
  const DebugDatabaseScreen({super.key});

  @override
  State<DebugDatabaseScreen> createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  String _dbPath = '';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _tournaments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _dbPath = await _db.getDatabasePath();

      final db = await _db.database;
      final users = await db.query('users');
      final favorites = await db.query('favorite_cards');
      final tournaments = await db.query('tournament_registrations');

      setState(() {
        _users = users;
        _favorites = favorites;
        _tournaments = tournaments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _db.deleteDatabase();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database reset successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug View'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Reset Database'),
                      content: const Text(
                        'This will delete all data and recreate the database. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetDatabase();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Database Path: $_dbPath'),
                    const SizedBox(height: 20),
                    const Text(
                      'Users:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          child: ListTile(
                            title: Text('Username: ${user['username']}'),
                            subtitle: Text(
                              'ID: ${user['id']}\nEmail: ${user['email']}\nFull Name: ${user['full_name']}',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Favorite Cards:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = _favorites[index];
                        return Card(
                          child: ListTile(
                            title: Text(favorite['name'] ?? 'No name'),
                            subtitle: Text(
                              'User ID: ${favorite['user_id']}\nCard ID: ${favorite['card_id']}',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tournament Registrations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tournaments.length,
                      itemBuilder: (context, index) {
                        final tournament = _tournaments[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              tournament['tournament_name'] ?? 'No name',
                            ),
                            subtitle: Text(
                              'User ID: ${tournament['user_id']}\n'
                              'Location: ${tournament['tournament_location']}\n'
                              'Date: ${tournament['tournament_date']}\n'
                              'Status: ${tournament['status']}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
