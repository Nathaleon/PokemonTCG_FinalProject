import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pokemon_card.dart';

class PokemonProvider extends ChangeNotifier {
  final String baseUrl = 'https://api.pokemontcg.io/v2';
  List<PokemonCard> _cards = [];
  Map<String, dynamic>? _selectedCard;
  final Map<String, Map<String, dynamic>> _cardCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _pendingFetches = {};
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;
  String? _selectedType;
  List<String> _types = [];

  List<PokemonCard> get cards => _cards;
  Map<String, dynamic>? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedType => _selectedType;
  List<String> get types => _types;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      _safeNotifyListeners();
    }
  }

  void clearSelectedCard() {
    if (_selectedCard != null) {
      _selectedCard = null;
    }
  }

  void setSelectedType(String? type) {
    _selectedType = type;
    fetchCards();
  }

  Future<void> fetchCards() async {
    if (_isLoading) return;

    _error = null;
    _setLoading(true);

    try {
      // Build query parameters
      String queryParams = 'pageSize=100'; // Increased from 30 to 100
      if (_selectedType != null) {
        queryParams += '&q=types:"$_selectedType"';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cards?$queryParams'),
        headers: {'X-Api-Key': dotenv.env['POKEMON_TCG_API_KEY'] ?? ''},
      );

      if (!_disposed) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _cards =
              (data['data'] as List)
                  .map((card) => PokemonCard.fromJson(card))
                  .toList();

          // Update types list if not already populated
          if (_types.isEmpty) {
            final typesSet = <String>{};
            for (var card in _cards) {
              if (card.type != null) {
                typesSet.add(card.type!);
              }
            }
            _types = typesSet.toList()..sort();
          }

          _safeNotifyListeners();
        } else {
          throw Exception('Failed to load cards');
        }
      }
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        print('Error fetching cards: $e');
        _safeNotifyListeners();
      }
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
    }
  }

  Future<Map<String, dynamic>?> getCardById(String id) async {
    // Check cache first
    if (_cardCache.containsKey(id)) {
      return _cardCache[id];
    }

    // Check if there's already a pending fetch for this card
    if (_pendingFetches.containsKey(id)) {
      return _pendingFetches[id];
    }

    // Create a new fetch
    _pendingFetches[id] = _fetchCardById(id);
    final result = await _pendingFetches[id];
    _pendingFetches.remove(id);

    return result;
  }

  Future<Map<String, dynamic>?> _fetchCardById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards/$id'),
        headers: {'X-Api-Key': dotenv.env['POKEMON_TCG_API_KEY'] ?? ''},
      );

      if (_disposed) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cardData = data['data'] as Map<String, dynamic>;
        _cardCache[id] = cardData;
        return cardData;
      } else {
        throw Exception('Failed to load card details');
      }
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        print('Error fetching card details: $e');
      }
      return null;
    }
  }

  Future<void> searchCards(String query) async {
    if (_isLoading) return;

    if (query.isEmpty) {
      await fetchCards();
      return;
    }

    _error = null;
    _setLoading(true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards?q=name:$query*'),
        headers: {'X-Api-Key': dotenv.env['POKEMON_TCG_API_KEY'] ?? ''},
      );

      if (!_disposed) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _cards =
              (data['data'] as List)
                  .map((card) => PokemonCard.fromJson(card))
                  .toList();
          _safeNotifyListeners();
        } else {
          throw Exception('Failed to search cards');
        }
      }
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        print('Error searching cards: $e');
        _safeNotifyListeners();
      }
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
    }
  }
}
