class BuySellItem {
  final String id;
  final String itemName;
  final String price;
  final String priceType;
  final String description;
  final String imageUrl;
  final String sellerName;
  final String sellerPhone;
  final String sellerApartment;
  final String dateTime;
  final String status;
  final String category;
  final String sellerId;

  BuySellItem({
    required this.id,
    required this.itemName,
    required this.price,
    required this.priceType,
    required this.description,
    required this.imageUrl,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerApartment,
    required this.dateTime,
    required this.status,
    required this.category,
    required this.sellerId,
  });

  factory BuySellItem.fromJson(Map<String, dynamic> json) {
    return BuySellItem(
      id: json['id'].toString(),
      itemName: json['item_name'] ?? json['itemName'] ?? '',
      price: json['price']?.toString() ?? '',
      priceType: json['price_type'] ?? json['priceType'] ?? 'fixed',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      sellerName: json['seller_name'] ?? json['sellerName'] ?? '',
      sellerPhone: json['seller_phone'] ?? json['sellerPhone'] ?? '',
      sellerApartment: json['seller_apartment'] ?? json['sellerApartment'] ?? '',
      dateTime: json['created_at'] ?? json['dateTime'] ?? '',
      status: json['status'] ?? 'active',
      category: json['category'] ?? 'Other',
      sellerId: (json['seller_id'] ?? json['sellerId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'price': price,
    'priceType': priceType,
    'description': description,
    'imageUrl': imageUrl,
    'sellerName': sellerName,
    'sellerPhone': sellerPhone,
    'sellerApartment': sellerApartment,
    'status': status,
    'category': category,
    'sellerId': sellerId,
  };
}
