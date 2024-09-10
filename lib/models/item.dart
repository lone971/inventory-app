class Item {
  final int id;
  final String name;
  final double buyingPrice;
  final double sellingPrice;
  final int stock;
  final int sold;
  final String image;

  Item({
    required this.id,
    required this.name,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.stock,
    required this.sold,
    required this.image,
  });

  // Convert an Item object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'sold': sold,
      'image': image,
    };
  }

  // Create an Item object from a Map object
  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      buyingPrice: map['buyingPrice'],
      sellingPrice: map['sellingPrice'],
      stock: map['stock'],
      sold: map['sold'],
      image: map['image'] ?? '', // Default to empty string if null
    );
  }

  // Calculate remaining stock
  int get remainingStock => stock - sold;
}
