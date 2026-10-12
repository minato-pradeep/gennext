class Offer {
  final int id;
  final String title;
  final String description;
  final String storeName;
  final String couponCode;
  final String discount;
  final String validUntil;
  final String imageUrl;
  final String category;
  final bool isActive;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.storeName,
    required this.couponCode,
    required this.discount,
    required this.validUntil,
    required this.imageUrl,
    required this.category,
    required this.isActive,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      storeName: json['storeName'] as String,
      couponCode: json['couponCode'] as String,
      discount: json['discount'] as String,
      validUntil: json['validUntil'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'storeName': storeName,
    'couponCode': couponCode,
    'discount': discount,
    'validUntil': validUntil,
    'imageUrl': imageUrl,
    'category': category,
    'isActive': isActive,
  };
}