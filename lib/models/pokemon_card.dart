class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;
  final String rarity;
  final String? type;
  final double? price;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rarity,
    this.type,
    this.price,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['images']?['small'] ?? '',
      rarity: json['rarity'] ?? '',
      type: json['types']?[0],
      price: json['cardmarket']?['prices']?['averageSellPrice']?.toDouble(),
    );
  }
}
