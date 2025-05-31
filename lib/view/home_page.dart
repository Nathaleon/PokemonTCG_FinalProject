// Import untuk widget Flutter dan komponen-komponen yang dibutuhkan
import 'package:flutter/material.dart';
import 'package:responsi_mobile/view/detailphone.dart';
import '../model/phone.dart';
import '../service/phone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Widget halaman utama yang menampilkan daftar smartphone
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Phone>> _phonesFuture;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  Set<int> favoritePhones = {};
  final TextEditingController _searchController = TextEditingController();
  List<Phone> _allPhones = [];
  List<Phone> _filteredPhones = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPhones();
    _loadFavorites();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredPhones = _allPhones;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredPhones =
          _allPhones.where((phone) {
            final searchTerm = _searchController.text.toLowerCase();
            return phone.name.toLowerCase().contains(searchTerm) ||
                phone.brand.toLowerCase().contains(searchTerm) ||
                phone.specification.toLowerCase().contains(searchTerm);
          }).toList();
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePhones =
          (prefs.getStringList('favorites') ?? [])
              .map((e) => int.parse(e))
              .toSet();
    });
  }

  Future<void> _toggleFavorite(int phoneId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoritePhones.contains(phoneId)) {
        favoritePhones.remove(phoneId);
      } else {
        favoritePhones.add(phoneId);
      }
    });
    await prefs.setStringList(
      'favorites',
      favoritePhones.map((e) => e.toString()).toList(),
    );
  }

  void _loadPhones() {
    setState(() {
      _phonesFuture = PhoneService().fetchPhones().then((phones) {
        _allPhones = phones;
        _filteredPhones = phones;
        return phones;
      });
    });
  }

  Future<void> _deletePhone(int id) async {
    try {
      final success = await PhoneService().deletePhone(id);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Phone deleted successfully')));
        _loadPhones();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete phone')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone List'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.pushNamed(context, '/favorites').then((_) {
                _loadPhones();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Create Phone',
            onPressed: () {
              Navigator.pushNamed(context, '/create').then((value) {
                if (value == true) {
                  _loadPhones();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedin');
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search phones...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadPhones();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Phone>>(
            future: _phonesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${snapshot.error}'.replaceAll(
                          'Exception: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPhones,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || _filteredPhones.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        _isSearching
                            ? 'No phones found matching your search'
                            : 'No phones found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      if (!_isSearching)
                        Text(
                          'Tap + to add a new phone',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _filteredPhones.length,
                itemBuilder: (context, index) {
                  final phone = _filteredPhones[index];
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
                        ).then((_) {
                          _loadPhones();
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    phone.brand,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
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
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    favoritePhones.contains(phone.id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        favoritePhones.contains(phone.id)
                                            ? Colors.red
                                            : null,
                                  ),
                                  onPressed: () => _toggleFavorite(phone.id),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/edit',
                                      arguments: {'id': phone.id},
                                    ).then((value) {
                                      if (value == true) {
                                        _loadPhones();
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('Delete Phone'),
                                            content: Text(
                                              'Are you sure you want to delete this phone?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deletePhone(phone.id);
                                                },
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                              ],
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
        ),
      ),
    );
  }
}
