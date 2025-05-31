// Import untuk widget Flutter dan shared preferences untuk menyimpan status login
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget halaman login yang dapat berubah state
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk mengelola input username dan password
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Status loading dan pesan error
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Cek status login saat halaman dibuka
  }

  // Fungsi untuk memeriksa apakah user sudah login sebelumnya
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedin') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Fungsi untuk memproses login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    var tempContext = Navigator.of(context);
    // Validasi username dan password (hardcoded untuk demo)
    if (_usernameController.text == '123220015' &&
        _passwordController.text == '123456') {
      // Simpan status login ke shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedin', true);
      tempContext.pushReplacementNamed('/home');
    } else {
      setState(() {
        _error = 'Invalid username or password';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Field input username
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Field input password (tersembunyi)
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Tampilkan pesan error jika ada
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
              // Tombol login dengan indikator loading
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
