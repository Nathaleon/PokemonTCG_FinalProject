import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:provider/provider.dart';
import 'package:pokemontcg/providers/auth_provider.dart';
import 'package:pokemontcg/screens/pokecard_screen.dart';
import 'package:pokemontcg/screens/marketplace_screen.dart';
import 'package:pokemontcg/screens/tournament_screen.dart';
import 'package:pokemontcg/screens/profile_screen.dart';
import 'package:pokemontcg/screens/favorite_cards_screen.dart';
import '../widgets/popular_cards_slider.dart';
import '../widgets/cart_icon.dart';
import '../widgets/country_selector.dart';
import '../services/location_service.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import '../data/tournament_locations.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;
  final List<Widget> _screens = [
    const PokeCardScreen(),
    const ProfileScreen(),
    const HomeContent(),
    const MarketplaceScreen(),
    const TournamentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteCardsScreen(),
                ),
              );
            },
          ),
          const CartIcon(),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.credit_card),
              ),
              label: 'PokeCard',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.person),
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.only(bottom: 3),
                child: Image.asset(
                  'assets/images/pokeball.png',
                  height: 24,
                  width: 24,
                ),
              ),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.store),
              ),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.emoji_events),
              ),
              label: 'Tournament',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _locationText = 'Detecting location...';
  bool _isLoadingLocation = true;
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _upcomingTournaments = [];
  bool _isLoadingTournaments = true;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadUpcomingTournaments();
    // Set up periodic location updates
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _getLocation(),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _getLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationText = 'Detecting location...';
    });

    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
        if (locationData['error']?.isNotEmpty ?? false) {
          _locationText = 'Location unavailable';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationData['error'] ?? 'Unknown error'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _locationText = '${locationData['city']}, ${locationData['country']}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
        _locationText = 'Location unavailable';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUpcomingTournaments() async {
    try {
      final tournaments = await _db.getUpcomingTournaments();
      if (mounted) {
        setState(() {
          _upcomingTournaments = tournaments;
          _isLoadingTournaments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
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
    // Carousel items with their navigation destinations
    final List<Map<String, dynamic>> carouselItems = [
      {
        'image': 'assets/images/banner5.png',
        'route': 0, // Index for PokeCard in bottom navigation
      },
      {
        'image': 'assets/images/banner4.png',
        'route': 3, // Index for Shop in bottom navigation
      },
      {
        'image': 'assets/images/banner1.png',
        'route': 4, // Index for Tournament in bottom navigation
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                _isLoadingLocation
                    ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      _locationText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                if (!_isLoadingLocation)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      setState(() {
                        _isLoadingLocation = true;
                        _locationText = 'Detecting location...';
                      });
                      _getLocation();
                    },
                  ),
              ],
            ),
          ),

          // Carousel
          FlutterCarousel(
            options: CarouselOptions(
              height: 150.0,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
            ),
            items:
                carouselItems.map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          // Update the selected index in the parent widget
                          final homeScreen =
                              context
                                  .findAncestorStateOfType<_HomeScreenState>();
                          if (homeScreen != null) {
                            homeScreen.setState(() {
                              homeScreen._selectedIndex = item['route'];
                            });
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              item['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),

          // Popular Cards Section
          const PopularCardsSlider(),

          // Upcoming Tournaments Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Tournaments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TournamentScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingTournaments)
                  const Center(child: CircularProgressIndicator())
                else if (_upcomingTournaments.isEmpty)
                  const Center(
                    child: Text(
                      'No upcoming tournaments',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _upcomingTournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = _upcomingTournaments[index];
                      final tournamentDate = DateTime.parse(
                        tournament['tournament_date'],
                      );
                      final location = _findTournamentLocation(
                        tournament['tournament_name'],
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                          ),
                          title: Text(tournament['tournament_name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tournament['tournament_location']),
                              if (location != null)
                                Text('Venue: ${location.venue}'),
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM y - HH:mm',
                                ).format(tournamentDate),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            if (location != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TournamentScreen(
                                        initialLocation: location,
                                      ),
                                ),
                              );
                            }
                          },
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
