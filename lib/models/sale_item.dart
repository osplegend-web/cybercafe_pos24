import '../core/utils/constants.dart';

class SaleItem {
  final int? id;
  final int? saleId;
  final SaleItemType itemType;
  final int itemId; // product id or service id
  final String itemName; // snapshot of name at sale time
  final double quantity;
  final double unitPrice; // snapshot of price at sale time
  final double purchasePrice; // snapshot, used for profit calc (0 for services)

  SaleItem({
    this.id,
    this.saleId,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    this.purchasePrice = 0,
  });

  double get totalPrice => quantity * unitPrice;
  double get profit => (unitPrice - purchasePrice) * quantity;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sale_id': saleId,
        'item_type': itemType.name,
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'purchase_price': purchasePrice,
        'total_price': totalPrice,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        id: map['id'] as int?,
        saleId: map['sale_id'] as int?,
        itemType: SaleItemTypeX.fromString(map['item_type'] as String? ?? 'product'),
        itemId: map['item_id'] as int,
        itemName: map['item_name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
      );
}
