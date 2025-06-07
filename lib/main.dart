import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pokemontcg/screens/splash_screen.dart';
import 'package:pokemontcg/screens/login_screen.dart';
import 'package:pokemontcg/screens/home_screen.dart';
import 'package:pokemontcg/screens/cart_screen.dart';
import 'package:pokemontcg/screens/purchase_history_screen.dart';
import 'package:pokemontcg/screens/pokecard_screen.dart';
import 'package:pokemontcg/screens/marketplace_screen.dart';
import 'package:pokemontcg/providers/auth_provider.dart';
import 'package:pokemontcg/providers/pokemon_provider.dart';
import 'package:pokemontcg/providers/favorites_provider.dart';
import 'package:pokemontcg/providers/cart_provider.dart';
import 'package:pokemontcg/providers/purchase_history_provider.dart';
import 'package:pokemontcg/providers/currency_provider.dart';
import 'services/notification_service.dart';
import 'services/time_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize services
  TimeService.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => PokemonProvider()),
        ChangeNotifierProvider(create: (ctx) => PurchaseHistoryProvider()),
        ChangeNotifierProvider(create: (ctx) => CurrencyProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = FavoritesProvider();
            provider.loadFavorites(); // Load favorites when app starts
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Pokemon TCG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.red,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          '/purchase-history': (context) {
            // Get userId from AuthProvider
            final userId =
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).userId?.toString() ??
                '';
            return PurchaseHistoryScreen(userId: userId);
          },
          '/cards': (context) => const PokeCardScreen(),
          '/marketplace': (context) => const MarketplaceScreen(),
        },
      ),
    );
  }
}
