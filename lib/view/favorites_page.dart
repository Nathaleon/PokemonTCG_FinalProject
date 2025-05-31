import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/phone.dart';
import '../service/phone_service.dart';
import 'package:intl/intl.dart';
import 'detailphone.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Phone>> _favoritePhonesFuture;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadFavoritePhones();
  }

  Future<void> _loadFavoritePhones() async {
    setState(() {
      _favoritePhonesFuture = _fetchFavoritePhones();
    });
  }

  Future<List<Phone>> _fetchFavoritePhones() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorites') ?? [];

    if (favoriteIds.isEmpty) {
      return [];
    }

    try {
      final allPhones = await PhoneService().fetchPhones();
      return allPhones
          .where((phone) => favoriteIds.contains(phone.id.toString()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load favorite phones: $e');
    }
  }

  Future<void> _removeFromFavorites(int phoneId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);

    favorites.remove(phoneId.toString());
    await prefs.setStringList('favorites', favorites.toList());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Removed from favorites')));

    _loadFavoritePhones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorite Phones')),
      body: FutureBuilder<List<Phone>>(
        future: _favoritePhonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}'.replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFavoritePhones,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorite phones yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add phones to favorites from the home page',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final phones = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: phones.length,
            itemBuilder: (context, index) {
              final phone = phones[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetailPhonePage(phoneId: phone.id),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _loadFavoritePhones();
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              phone.imgUrl.isNotEmpty
                                  ? Image.network(
                                    phone.imgUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.phone_android,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.phone_android,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phone.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                phone.brand,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                currencyFormat.format(phone.price),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromFavorites(phone.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
