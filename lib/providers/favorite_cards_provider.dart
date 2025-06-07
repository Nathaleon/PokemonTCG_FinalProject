import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/pokemon_card.dart';

class FavoriteCardsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PokemonCard> _favoriteCards = [];

  List<PokemonCard> get favoriteCards => [..._favoriteCards];

  Future<void> loadFavoriteCards(int userId) async {
    final cards = await _dbHelper.getFavoriteCards(userId);
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

  Future<void> addToFavorites(int userId, PokemonCard card) async {
    final cardData = {
      'user_id': userId,
      'card_id': card.id,
      'name': card.name,
      'image_url': card.imageUrl,
      'type': card.type,
      'rarity': card.rarity,
      'price': card.price,
    };

    await _dbHelper.addFavoriteCard(cardData);
    await loadFavoriteCards(userId);
  }

  Future<void> removeFromFavorites(int userId, String cardId) async {
    await _dbHelper.removeFavoriteCard(userId, cardId);
    await loadFavoriteCards(userId);
  }

  Future<bool> isFavorite(int userId, String cardId) async {
    return await _dbHelper.isCardFavorite(userId, cardId);
  }
}
