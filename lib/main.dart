// Import statements untuk mengakses widget Flutter dan halaman-halaman aplikasi
import 'package:flutter/material.dart';
import 'view/createphone.dart';
import 'view/detailphone.dart';
import 'view/editphone.dart';
import 'view/home_page.dart';
import 'view/login_page.dart';
import 'view/favorites_page.dart';

// Entry point aplikasi
void main() {
  runApp(const MyApp());
}

// Widget utama yang menjadi root dari aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menghilangkan banner debug di pojok kanan atas
      debugShowCheckedModeBanner: false,
      title: 'RESPONSI MOBILE',
      // Konfigurasi tema aplikasi dengan warna utama deep purple
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Rute awal aplikasi adalah halaman login
      initialRoute: '/',
      // Definisi rute-rute dalam aplikasi untuk navigasi
      routes: {
        '/': (context) => LoginPage(), // Halaman login sebagai halaman awal
        '/home': (context) => HomePage(), // Halaman utama setelah login
        '/create':
            (context) => CreatePhonePage(), // Halaman untuk membuat phone baru
        '/edit': (context) => EditPhonePage(), // Halaman untuk mengedit phone
        '/favorites': (context) => FavoritesPage(), // Halaman favorit
      },
    );
  }
}
