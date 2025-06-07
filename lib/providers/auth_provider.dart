import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _db = DatabaseHelper();
  bool _isAuthenticated = false;
  String? _username;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  int? get userId => _userId;

  // Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> updateUsername(String newUsername) async {
    await _storage.write(key: 'username', value: newUsername);
    _username = newUsername;
    notifyListeners();
  }

  Future<void> verifyPassword(String username, String password) async {
    final user = await _db.getUser(username);
    if (user == null) {
      throw Exception('User not found');
    }

    final hashedPassword = hashPassword(password);
    if (user['password_hash'] != hashedPassword) {
      throw Exception('Invalid password');
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final user = await _db.getUser(username);
      if (user == null) {
        throw Exception('User not found');
      }

      final hashedPassword = hashPassword(password);
      if (user['password_hash'] != hashedPassword) {
        throw Exception('Invalid password');
      }

      await _storage.write(key: 'username', value: username);
      await _storage.write(key: 'user_id', value: user['id'].toString());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedin', true);

      _username = username;
      _userId = user['id'];
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid username or password');
    }
  }

  Future<void> register(
    String username,
    String password,
    String email, {
    String? fullName,
    int? age,
    String? country,
    String? city,
  }) async {
    try {
      // Check if email is already taken
      final isEmailExists = await _db.isEmailTaken(email);
      if (isEmailExists) {
        throw Exception(
          'This email is already registered. Please use a different email or try logging in.',
        );
      }

      final hashedPassword = hashPassword(password);

      final userData = {
        'username': username,
        'email': email,
        'password_hash': hashedPassword,
        'full_name': fullName,
        'age': age,
        'country': country,
        'city': city,
      };

      await _db.insertUser(userData);

      // Registration successful but don't auto login
      // Let user go back to login screen
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: users.username')) {
        throw Exception(
          'This username is already taken. Please choose a different username.',
        );
      } else if (e.toString().contains(
        'UNIQUE constraint failed: users.email',
      )) {
        throw Exception(
          'This email is already registered. Please use a different email or try logging in.',
        );
      } else {
        throw Exception('Registration failed: ${e.toString()}');
      }
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedin', false);
    _isAuthenticated = false;
    _username = null;
    _userId = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedin') ?? false;
    final username = await _storage.read(key: 'username');
    final userIdStr = await _storage.read(key: 'user_id');

    if (isLoggedIn && username != null && userIdStr != null) {
      _username = username;
      _userId = int.parse(userIdStr);
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}
