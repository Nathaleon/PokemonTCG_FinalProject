import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/pokemon_card.dart';

class FavoritesProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PokemonCard> _favoriteCards = [];
  int? _currentUserId;

  List<PokemonCard> get favoriteCards => [..._favoriteCards];

  void setCurrentUser(int userId) {
    _currentUserId = userId;
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (_currentUserId == null) return;

    final cards = await _dbHelper.getFavoriteCards(_currentUserId!);
    _favoriteCards =
        cards
            .map(
              (card) => PokemonCard(
                id: card['card_id'],
                name: card['name'],
                imageUrl: card['image_url'],
                type: card['type'],
                rarity: card['rarity'] ?? 'Unknown',
                price:
                    card['price'] != null
                        ? double.parse(card['price'].toString())
                        : null,
              ),
            )
            .toList();
    notifyListeners();
  }

  Future<void> addToFavorites(PokemonCard card) async {
    if (_currentUserId == null) return;

    final cardData = {
      'user_id': _currentUserId,
      'card_id': card.id,
      'name': card.name,
      'image_url': card.imageUrl,
      'type': card.type,
      'rarity': card.rarity,
      'price': card.price,
    };

    await _dbHelper.addFavoriteCard(cardData);
    await loadFavorites();
  }

  Future<void> removeFromFavorites(String cardId) async {
    if (_currentUserId == null) return;

    await _dbHelper.removeFavoriteCard(_currentUserId!, cardId);
    await loadFavorites();
  }

  Future<bool> isFavorite(String cardId) async {
    if (_currentUserId == null) return false;
    return await _dbHelper.isCardFavorite(_currentUserId!, cardId);
  }
}
