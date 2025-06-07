import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pokemon_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../models/pokemon_card.dart';
import '../services/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CardDetailScreen extends StatefulWidget {
  final String cardId;

  const CardDetailScreen({Key? key, required this.cardId}) : super(key: key);

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late PokemonProvider _provider;
  Map<String, dynamic>? _cardData;
  bool _isFavorite = false;
  final _notificationService = NotificationService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<PokemonProvider>(context, listen: false);
    _loadCardData();
    _checkFavoriteStatus();
  }

  Future<void> _loadCardData() async {
    final data = await _provider.getCardById(widget.cardId);
    if (mounted) {
      setState(() {
        _cardData = data;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      final isFav = await favoritesProvider.isFavorite(widget.cardId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    if (_cardData == null) return;

    final card = PokemonCard(
      id: widget.cardId,
      name: _cardData!['name'] ?? 'Unknown',
      imageUrl: _cardData!['images']['small'] ?? '',
      type: _cardData!['types']?.first as String?,
      rarity: _cardData!['rarity'] ?? 'Unknown',
      price: _cardData!['cardmarket']?['prices']?['averageSellPrice'],
    );

    if (_isFavorite) {
      await favoritesProvider.removeFromFavorites(widget.cardId);
    } else {
      await favoritesProvider.addToFavorites(card);
      await _notificationService.showFavoriteNotification(card.name);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'Kartu ${card.name} berhasil ditambahkan ke favorit'
                : 'Kartu ${card.name} dihapus dari favorit',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Card Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  _isFavorite ? const Color.fromARGB(255, 255, 255, 255) : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body:
          _cardData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            _cardData!['images']['large'] ?? '',
                                        fit: BoxFit.contain,
                                        placeholder:
                                            (context, url) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget:
                                            (context, url, error) =>
                                                const Icon(Icons.error),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: GestureDetector(
                                        onTap:
                                            () => Navigator.of(context).pop(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Hero(
                          tag: 'pokemon_card_${_cardData!['id']}',
                          child: CachedNetworkImage(
                            imageUrl: _cardData!['images']['large'] ?? '',
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    'Name',
                                    _cardData!['name'] ?? 'Unknown',
                                  ),
                                  _buildInfoRow(
                                    'Series',
                                    _cardData!['set']['series'] ?? 'Unknown',
                                  ),
                                  _buildInfoRow(
                                    'Set',
                                    _cardData!['set']['name'] ?? 'Unknown',
                                  ),
                                  _buildInfoRow(
                                    'Number',
                                    '${_cardData!['number']} / ${_cardData!['set']['printedTotal']}',
                                  ),
                                  _buildInfoRow(
                                    'Rarity',
                                    _cardData!['rarity'] ?? 'Unknown',
                                  ),
                                  if (_cardData!['types'] != null)
                                    _buildInfoRow(
                                      'Types',
                                      (_cardData!['types'] as List).join(', '),
                                    ),
                                  if (_cardData!['hp'] != null)
                                    _buildInfoRow('HP', _cardData!['hp']),
                                  if (_cardData!['attacks'] != null)
                                    _buildInfoRow(
                                      'Attacks',
                                      (_cardData!['attacks'] as List)
                                          .map((attack) => attack['name'])
                                          .join(', '),
                                    ),
                                  if (_cardData!['weaknesses'] != null)
                                    _buildInfoRow(
                                      'Weaknesses',
                                      (_cardData!['weaknesses'] as List)
                                          .map(
                                            (w) =>
                                                '${w['type']} (${w['value']})',
                                          )
                                          .join(', '),
                                    ),
                                  _buildInfoRow(
                                    'Artist',
                                    _cardData!['artist'] ?? 'Unknown',
                                  ),
                                  if (_cardData!['cardmarket'] != null)
                                    _buildInfoRow(
                                      'Last Updated',
                                      _cardData!['cardmarket']['updatedAt'] ??
                                          'Unknown',
                                    ),
                                  if (_cardData!['tcgplayer'] != null)
                                    _buildInfoRow(
                                      'TCG Player URL',
                                      _cardData!['tcgplayer']['url'] ??
                                          'Not available',
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_cardData!['abilities'] != null)
                            _buildAbilities(_cardData!['abilities'] as List),
                          if (_cardData!['tcgplayer']?['prices'] != null)
                            _buildPriceInfo(_cardData!['tcgplayer']['prices']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildAbilities(List abilities) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...abilities
                .map(
                  (ability) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ability['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (ability['text'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ability['text'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo(Map<String, dynamic> prices) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Prices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            if (prices['holofoil'] != null) ...[
              _buildPriceRow('Holofoil', prices['holofoil']['market']),
              _buildPriceRow('Holofoil Low', prices['holofoil']['low']),
              _buildPriceRow('Holofoil High', prices['holofoil']['high']),
            ],
            if (prices['normal'] != null) ...[
              _buildPriceRow('Normal', prices['normal']['market']),
              _buildPriceRow('Normal Low', prices['normal']['low']),
              _buildPriceRow('Normal High', prices['normal']['high']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            _formatPrice(price),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    return '\$${double.parse(price.toString()).toStringAsFixed(2)}';
  }
}
