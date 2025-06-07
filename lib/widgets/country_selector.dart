import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class CountrySelector extends StatelessWidget {
  const CountrySelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return PopupMenuButton<String>(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Currency: ${currencyProvider.selectedCountry}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          onSelected: (String countryCode) {
            currencyProvider.setCountry(countryCode);
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'US',
                child: _buildCountryItem('United States', 'USD', 'US'),
              ),
              PopupMenuItem(
                value: 'ID',
                child: _buildCountryItem('Indonesia', 'IDR', 'ID'),
              ),
              PopupMenuItem(
                value: 'JP',
                child: _buildCountryItem('Japan', 'JPY', 'JP'),
              ),
              PopupMenuItem(
                value: 'GB',
                child: _buildCountryItem('United Kingdom', 'GBP', 'GB'),
              ),
              PopupMenuItem(
                value: 'EU',
                child: _buildCountryItem('European Union', 'EUR', 'EU'),
              ),
              PopupMenuItem(
                value: 'AU',
                child: _buildCountryItem('Australia', 'AUD', 'AU'),
              ),
              PopupMenuItem(
                value: 'SG',
                child: _buildCountryItem('Singapore', 'SGD', 'SG'),
              ),
              PopupMenuItem(
                value: 'MY',
                child: _buildCountryItem('Malaysia', 'MYR', 'MY'),
              ),
            ];
          },
        );
      },
    );
  }

  Widget _buildCountryItem(String country, String currency, String code) {
    return Row(
      children: [
        Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(country)),
        Text(
          currency,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
