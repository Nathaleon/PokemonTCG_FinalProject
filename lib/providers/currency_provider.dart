import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CurrencyProvider with ChangeNotifier {
  String _selectedCountry = 'US';
  String _selectedCurrency = 'USD';
  double _exchangeRate = 1.0;
  final Map<String, String> _countryCurrencies = {
    'US': 'USD',
    'ID': 'IDR',
    'JP': 'JPY',
    'GB': 'GBP',
    'EU': 'EUR',
    'AU': 'AUD',
    'SG': 'SGD',
    'MY': 'MYR',
  };

  String get selectedCountry => _selectedCountry;
  String get selectedCurrency => _selectedCurrency;
  double get exchangeRate => _exchangeRate;
  Map<String, String> get countryCurrencies => _countryCurrencies;

  CurrencyProvider() {
    _loadSavedCountry();
  }

  Future<void> _loadSavedCountry() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCountry = prefs.getString('selected_country') ?? 'US';
    _selectedCurrency = _countryCurrencies[_selectedCountry] ?? 'USD';
    await updateExchangeRate();
  }

  Future<void> setCountry(String countryCode) async {
    if (_countryCurrencies.containsKey(countryCode)) {
      _selectedCountry = countryCode;
      _selectedCurrency = _countryCurrencies[countryCode] ?? 'USD';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_country', countryCode);

      await updateExchangeRate();
      notifyListeners();
    }
  }

  Future<void> updateExchangeRate() async {
    if (_selectedCurrency == 'USD') {
      _exchangeRate = 1.0;
      return;
    }

    try {
      final apiKey = dotenv.env['EXCHANGE_RATE_API_KEY'];
      final response = await http.get(
        Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRate = data['conversion_rates'][_selectedCurrency] ?? 1.0;
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
      _exchangeRate = 1.0;
    }
    notifyListeners();
  }

  double convertPrice(double usdPrice) {
    return usdPrice * _exchangeRate;
  }

  String formatPrice(double price) {
    String symbol = getCurrencySymbol(_selectedCurrency);
    return '$symbol ${price.toStringAsFixed(2)}';
  }

  String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'IDR':
        return 'Rp';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'AUD':
        return 'A\$';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      default:
        return '\$';
    }
  }
}
