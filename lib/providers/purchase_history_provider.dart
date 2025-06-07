import 'package:flutter/foundation.dart';
import '../models/purchase_history.dart';
import '../models/cart_item.dart';
import '../database/database_helper.dart';

class PurchaseHistoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<PurchaseHistory> _history = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseHistory> get history => [..._history];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHistory(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final purchases = await _db.getUserPurchases(int.parse(userId));
      _history = [];

      for (var purchase in purchases) {
        final items = await _db.getPurchaseItems(purchase['id']);
        _history.add(
          PurchaseHistory(
            id: purchase['id'].toString(),
            userId: userId,
            items:
                items
                    .map(
                      (item) => PurchaseItem(
                        cardId: item['card_id'],
                        name: item['name'],
                        imageUrl: item['image_url'],
                        price: item['price'],
                        quantity: item['quantity'],
                      ),
                    )
                    .toList(),
            totalAmount: purchase['total_amount'],
            currency: purchase['currency'],
            purchaseDate: DateTime.parse(purchase['purchase_date']),
          ),
        );
      }
    } catch (e) {
      _error = 'Failed to load purchase history: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPurchase(
    String userId,
    List<CartItem> items,
    double totalAmount,
    String currency,
  ) async {
    final purchase = {
      'user_id': int.parse(userId),
      'total_amount': totalAmount,
      'currency': currency,
    };

    final purchaseItems =
        items
            .map(
              (item) => {
                'card_id': item.cardId,
                'name': item.name,
                'image_url': item.imageUrl,
                'price': item.price,
                'quantity': item.quantity,
              },
            )
            .toList();

    await _db.addPurchase(purchase, purchaseItems);
    await loadHistory(userId);
  }

  Future<void> deletePurchase(String userId, String purchaseId) async {
    await _db.deletePurchase(int.parse(purchaseId));
    await loadHistory(userId);
  }

  Future<void> clearAllHistory(String userId) async {
    await _db.clearPurchaseHistory(int.parse(userId));
    await loadHistory(userId);
  }

  List<PurchaseHistory> getUserHistory(String userId) {
    return _history.where((purchase) => purchase.userId == userId).toList();
  }
}
