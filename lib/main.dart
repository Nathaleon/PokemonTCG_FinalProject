import 'package:flutter/material.dart';
import 'view/createphone.dart';
import 'view/detailphone.dart';
import 'view/editphone.dart';
import 'view/home_page.dart';
import 'view/login_page.dart';
import 'view/favorites_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RESPONSI MOBILE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/create': (context) => CreatePhonePage(),
        '/edit': (context) => EditPhonePage(),
        '/favorites': (context) => FavoritesPage(),
      },
    );
  }
}
