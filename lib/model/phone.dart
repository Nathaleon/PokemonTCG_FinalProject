class Phone {
  final int id;
  final String name;
  final String brand;
  final int price;
  final String imgUrl;
  final String specification;
  final DateTime createdAt;
  final DateTime updatedAt;

  Phone({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imgUrl,
    required this.specification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    return Phone(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      price: json['price'],
      imgUrl: json['img_url'],
      specification: json['specification'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
