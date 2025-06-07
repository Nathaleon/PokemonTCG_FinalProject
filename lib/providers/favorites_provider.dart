import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/pokemon_card.dart';

class FavoritesProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PokemonCard> _favoriteCards = [];
  int? _currentUserId;

  List<PokemonCard> get favoriteCards => [..._favoriteCards];

  // Called when user logs in
  Future<void> setCurrentUser(int userId) async {
    _currentUserId = userId;
    await loadFavorites(); // Ensure favorites are loaded after setting user
  }

  Future<void> loadFavorites() async {
    if (_currentUserId == null) return;

    try {
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
    } catch (e) {
      print('Error loading favorites: $e');
      _favoriteCards = []; // Reset favorites on error
      notifyListeners();
    }
  }

  Future<void> addToFavorites(PokemonCard card) async {
    if (_currentUserId == null) return;

    try {
      final cardData = {
        'user_id': _currentUserId,
        'card_id': card.id,
        'name': card.name,
        'image_url': card.imageUrl,
        'type': card.type,
        'rarity': card.rarity,
        'price': card.price,
      };

      final result = await _dbHelper.addFavoriteCard(cardData);
      if (result > 0) {
        // Check if insert was successful
        if (!_favoriteCards.any((c) => c.id == card.id)) {
          _favoriteCards.add(card);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(String cardId) async {
    if (_currentUserId == null) return;

    try {
      final result = await _dbHelper.removeFavoriteCard(
        _currentUserId!,
        cardId,
      );
      if (result > 0) {
        // Check if delete was successful
        _favoriteCards.removeWhere((card) => card.id == cardId);
        notifyListeners();
      }
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  Future<bool> isFavorite(String cardId) async {
    if (_currentUserId == null) return false;

    // First check in memory
    if (_favoriteCards.any((card) => card.id == cardId)) {
      return true;
    }

    // Then check in database
    try {
      final isInDb = await _dbHelper.isCardFavorite(_currentUserId!, cardId);
      if (isInDb) {
        // If it's in DB but not in memory, reload favorites
        await loadFavorites();
      }
      return isInDb;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Clear favorites when user logs out
  void clear() {
    _currentUserId = null;
    _favoriteCards = [];
    notifyListeners();
  }
}
