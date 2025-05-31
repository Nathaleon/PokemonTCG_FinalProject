import 'package:flutter/material.dart';
import '../service/phone_service.dart';
import '../model/phone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPhonePage extends StatefulWidget {
  final int phoneId;
  const DetailPhonePage({super.key, required this.phoneId});

  @override
  _DetailPhonePageState createState() => _DetailPhonePageState();
}

class _DetailPhonePageState extends State<DetailPhonePage> {
  late Future<Phone> _phoneDetailFuture;
  bool isFavorite = false;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPhoneDetail();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      isFavorite = favorites.contains(widget.phoneId.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);

    setState(() {
      if (isFavorite) {
        favorites.remove(widget.phoneId.toString());
      } else {
        favorites.add(widget.phoneId.toString());
      }
      isFavorite = !isFavorite;
    });

    await prefs.setStringList('favorites', favorites.toList());
  }

  void _loadPhoneDetail() {
    _phoneDetailFuture = PhoneService().fetchPhoneDetail(widget.phoneId);
  }

  Future<void> _deletePhone(BuildContext context) async {
    try {
      final success = await PhoneService().deletePhone(widget.phoneId);
      if (success) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Phone deleted successfully')));
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete phone')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Phone Detail'),
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit',
                  arguments: {'id': widget.phoneId},
                ).then((value) {
                  if (value == true) {
                    _loadPhoneDetail();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
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
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deletePhone(context);
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<Phone>(
          future: _phoneDetailFuture,
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
                      onPressed: _loadPhoneDetail,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return Center(child: Text('Phone not found.'));
            }

            final phone = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          phone.imgUrl.isNotEmpty
                              ? Image.network(
                                phone.imgUrl,
                                height: 300,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 300,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.phone_android,
                                        size: 100,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                              : Container(
                                height: 300,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.phone_android,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    phone.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    phone.brand,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    currencyFormat.format(phone.price),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Specification',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    phone.specification,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow('Created', phone.createdAt),
                  SizedBox(height: 4),
                  _buildInfoRow('Last Updated', phone.updatedAt),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, DateTime dateTime) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
        Text(
          DateFormat('dd MMM yyyy, HH:mm').format(dateTime),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
