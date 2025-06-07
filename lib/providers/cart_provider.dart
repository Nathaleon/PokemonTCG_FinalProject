import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get itemCount {
    return _items.length;
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart');
    if (cartData != null) {
      final List<dynamic> decodedData = json.decode(cartData);
      _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(_items.map((item) => item.toJson()).toList());
    await prefs.setString('cart', cartData);
  }

  void addItem(String cardId, String name, String imageUrl, double price) {
    final existingCartItemIndex = _items.indexWhere(
      (item) => item.cardId == cardId,
    );

    if (existingCartItemIndex >= 0) {
      _items[existingCartItemIndex].quantity += 1;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().toString(),
          cardId: cardId,
          name: name,
          imageUrl: imageUrl,
          price: price,
        ),
      );
    }

    notifyListeners();
    saveCart();
  }

  void removeItem(String cardId) {
    _items.removeWhere((item) => item.cardId == cardId);
    notifyListeners();
    saveCart();
  }

  void updateQuantity(String cardId, int quantity) {
    final index = _items.indexWhere((item) => item.cardId == cardId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
      saveCart();
    }
  }

  Future<void> checkout() async {
    _items = [];
    notifyListeners();
    saveCart();
  }

  void clear() {
    _items = [];
    notifyListeners();
    saveCart();
  }
}
