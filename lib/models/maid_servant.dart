class MaidServant {
  final int id;
  final String name;
  final int age;
  final String imageUrl;
  final String idNumber;
  final String address;
  final List<String> flatsServed; // up to 2 flat numbers
  final bool isActive;
  final String createdAt;

  MaidServant({
    required this.id,
    required this.name,
    required this.age,
    this.imageUrl = '',
    required this.idNumber,
    required this.address,
    required this.flatsServed,
    this.isActive = true,
    required this.createdAt,
  });

  factory MaidServant.fromJson(Map<String, dynamic> json) {
    // flats_served may arrive as a JSON array string or a real List
    List<String> parseFlats(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) {
        try {
          // Server stores as JSON string e.g. '["A-101","B-202"]'
          final decoded = raw.trim();
          if (decoded.startsWith('[')) {
            // Proper JSON array string
            final stripped = decoded.replaceAll(RegExp(r'[\[\]"]'), '');
            return stripped
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          return [decoded];
        } catch (_) {
          return [raw];
        }
      }
      return [];
    }

    return MaidServant(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      idNumber: json['id_number'] ?? json['idNumber'] ?? '',
      address: json['address'] ?? '',
      flatsServed: parseFlats(json['flats_served'] ?? json['flatsServed']),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at']?.toString() ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'image_url': imageUrl,
        'id_number': idNumber,
        'address': address,
        'flats_served': flatsServed,
        'is_active': isActive,
      };

  MaidServant copyWith({bool? isActive}) => MaidServant(
        id: id,
        name: name,
        age: age,
        imageUrl: imageUrl,
        idNumber: idNumber,
        address: address,
        flatsServed: flatsServed,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
