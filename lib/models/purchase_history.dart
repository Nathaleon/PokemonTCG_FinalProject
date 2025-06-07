class PurchaseHistory {
  final String id;
  final String userId;
  final List<PurchaseItem> items;
  final double totalAmount;
  final String currency;
  final DateTime purchaseDate;

  PurchaseHistory({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.purchaseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      id: json['id'],
      userId: json['userId'],
      items:
          (json['items'] as List)
              .map((item) => PurchaseItem.fromJson(item))
              .toList(),
      totalAmount: json['totalAmount'],
      currency: json['currency'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
    );
  }
}

class PurchaseItem {
  final String cardId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  PurchaseItem({
    required this.cardId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      cardId: json['cardId'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }
}
