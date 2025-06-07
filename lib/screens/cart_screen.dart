import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/purchase_history_provider.dart';
import '../widgets/country_selector.dart';
import '../services/location_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (!mounted) return;

      if (locationData['error']?.isNotEmpty ?? false) {
        // If location detection fails, set to USD but don't show error
        final currencyProvider = Provider.of<CurrencyProvider>(
          context,
          listen: false,
        );
        await currencyProvider.setCountry('US');
      }
    } catch (e) {
      // On error, default to USD silently
      if (mounted) {
        final currencyProvider = Provider.of<CurrencyProvider>(
          context,
          listen: false,
        );
        await currencyProvider.setCountry('US');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _handleCheckout(CartProvider cart, String userId) async {
    try {
      setState(() => _isProcessing = true);

      final currencyProvider = Provider.of<CurrencyProvider>(
        context,
        listen: false,
      );

      // Add to purchase history
      await Provider.of<PurchaseHistoryProvider>(
        context,
        listen: false,
      ).addPurchase(
        userId,
        cart.items,
        cart.totalAmount,
        currencyProvider.selectedCurrency,
      );

      // Clear the cart
      await cart.checkout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful! Check your purchase history.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing purchase: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          // Purchase History Button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              final userId =
                  Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).userId?.toString() ??
                  '';
              Navigator.pushNamed(context, '/purchase-history');
            },
          ),
          // Currency Selector with loading indicator
          _isLoadingLocation
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
              : const CountrySelector(),
        ],
      ),
      body: Consumer3<CartProvider, CurrencyProvider, AuthProvider>(
        builder: (
          context,
          cartProvider,
          currencyProvider,
          authProvider,
          child,
        ) {
          if (!authProvider.isAuthenticated) {
            return const Center(child: Text('Please login to view your cart'));
          }

          final userId = authProvider.userId?.toString() ?? '';

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              // Currency Info Row
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Prices shown in ${currencyProvider.selectedCountry}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    if (!_isLoadingLocation)
                      TextButton(
                        onPressed: _initializeLocation,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 16),
                            SizedBox(width: 4),
                            Text('Update'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          currencyProvider.formatPrice(
                            currencyProvider.convertPrice(item.price),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  cartProvider.updateQuantity(
                                    item.cardId,
                                    item.quantity - 1,
                                  );
                                } else {
                                  cartProvider.removeItem(item.cardId);
                                }
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                cartProvider.updateQuantity(
                                  item.cardId,
                                  item.quantity + 1,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                cartProvider.removeItem(item.cardId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyProvider.formatPrice(
                            currencyProvider.convertPrice(
                              cartProvider.totalAmount,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed:
                          _isProcessing || cartProvider.items.isEmpty
                              ? null
                              : () => _handleCheckout(cartProvider, userId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Checkout',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
