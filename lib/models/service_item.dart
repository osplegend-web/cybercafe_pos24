class ServiceItem {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final bool active;

  ServiceItem({
    this.id,
    required this.name,
    required this.price,
    this.description,
    this.active = true,
  });

  ServiceItem copyWith({
    int? id,
    String? name,
    double? price,
    String? description,
    bool? active,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'description': description,
        'active': active ? 1 : 0,
      };

  factory ServiceItem.fromMap(Map<String, dynamic> map) => ServiceItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        description: map['description'] as String?,
        active: (map['active'] as int? ?? 1) == 1,
      );
}
