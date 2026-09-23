import '../core/utils/constants.dart';
import 'sale_item.dart';

class Sale {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double amountPaid;
  final double changeAmount;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final bool isVoided;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeAmount,
    required this.paymentMethod,
    DateTime? createdAt,
    this.isVoided = false,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalProfit => items.fold(0.0, (sum, i) => sum + i.profit);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'subtotal': subtotal,
        'discount': discount,
        'grand_total': grandTotal,
        'amount_paid': amountPaid,
        'change_amount': changeAmount,
        'payment_method': paymentMethod.name,
        'created_at': createdAt.toIso8601String(),
        'is_voided': isVoided ? 1 : 0,
      };

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem> items = const []}) => Sale(
        id: map['id'] as int?,
        invoiceNumber: map['invoice_number'] as String,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String?,
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num).toDouble(),
        grandTotal: (map['grand_total'] as num).toDouble(),
        amountPaid: (map['amount_paid'] as num).toDouble(),
        changeAmount: (map['change_amount'] as num).toDouble(),
        paymentMethod: PaymentMethodX.fromString(map['payment_method'] as String? ?? 'cash'),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        isVoided: (map['is_voided'] as int? ?? 0) == 1,
        items: items,
      );
}
