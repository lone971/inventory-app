class Item {
  final int id;
  final String name;
  final double price;
  final int stock;
  final int sold;
  final String image;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'sold': sold,
      'remaining': stock - sold, // Calculated dynamically
      'image': image,
    };
  }

  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      sold: map['sold'],
      image: map['image'] ?? '', // Default to empty string if null
    );
  }
}
