class Product {
  final int? id;
  final String name;
  final int? categoryId;
  final String? categoryName; // populated via join, not persisted directly
  final String? sku;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQty;
  final double minStock;
  final String unit;
  final String? imagePath;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.sku,
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQty,
    required this.minStock,
    required this.unit,
    this.imagePath,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => stockQty <= minStock;

  double get stockValue => stockQty * purchasePrice;

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? categoryName,
    String? sku,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    double? stockQty,
    double? minStock,
    String? unit,
    String? imagePath,
    String? description,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQty: stockQty ?? this.stockQty,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category_id': categoryId,
        'sku': sku,
        'barcode': barcode,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock_qty': stockQty,
        'min_stock': minStock,
        'unit': unit,
        'image_path': imagePath,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        categoryId: map['category_id'] as int?,
        categoryName: map['category_name'] as String?,
        sku: map['sku'] as String?,
        barcode: map['barcode'] as String?,
        purchasePrice: (map['purchase_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        stockQty: (map['stock_qty'] as num).toDouble(),
        minStock: (map['min_stock'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'pcs',
        imagePath: map['image_path'] as String?,
        description: map['description'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
}
