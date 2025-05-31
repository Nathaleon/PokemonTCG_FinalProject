class PhoneDetail {
  final int id;
  final String name;
  final String brand;
  final int price;
  final String imgUrl;
  final String specification;

  PhoneDetail({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imgUrl,
    required this.specification,
  });

  factory PhoneDetail.fromJson(Map<String, dynamic> json) {
    return PhoneDetail(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      price: json['price'],
      imgUrl: json['imgUrl'],
      specification: json['specification'],
    );
  }
}
