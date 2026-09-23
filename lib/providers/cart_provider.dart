import 'package:flutter/foundation.dart';

import '../core/utils/constants.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/service_item.dart';
import '../services/sale_repository.dart';

class CartLine {
  final SaleItemType type;
  final int itemId;
  final String name;
  final double unitPrice;
  final double purchasePrice; // 0 for services
  final double availableStock; // ignored for services
  double quantity;

  CartLine({
    required this.type,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    this.purchasePrice = 0,
    this.availableStock = double.infinity,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final _saleRepo = SaleRepository();

  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);

  double discount = 0;
  PaymentMethod paymentMethod = PaymentMethod.cash;
  double amountPaid = 0;
  Customer? customer;

  double get subtotal => _lines.fold(0.0, (sum, l) => sum + l.total);
  double get grandTotal => (subtotal - discount).clamp(0, double.infinity);
  double get changeAmount => (amountPaid - grandTotal).clamp(0, double.infinity);
  bool get isEmpty => _lines.isEmpty;

  void addProduct(Product product, {double quantity = 1}) {
    final existing = _lines.indexWhere(
      (l) => l.type == SaleItemType.product && l.itemId == product.id,
    );
    if (existing >= 0) {
      _lines[existing].quantity += quantity;
    } else {
      _lines.add(CartLine(
        type: SaleItemType.product,
        itemId: product.id!,
        name: product.name,
        unitPrice: product.sellingPrice,
        purchasePrice: product.purchasePrice,
        availableStock: product.stockQty,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void addService(ServiceItem service, {double quantity = 1}) {
    final existing = _lines.indexWhere(
      (l) => l.type == SaleItemType.service && l.itemId == service.id,
    );
    if (existing >= 0) {
      _lines[existing].quantity += quantity;
    } else {
      _lines.add(CartLine(
        type: SaleItemType.service,
        itemId: service.id!,
        name: service.name,
        unitPrice: service.price,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    if (quantity <= 0) {
      removeLine(index);
      return;
    }
    _lines[index].quantity = quantity;
    notifyListeners();
  }

  void removeLine(int index) {
    _lines.removeAt(index);
    notifyListeners();
  }

  void setDiscount(double value) {
    discount = value;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setAmountPaid(double value) {
    amountPaid = value;
    notifyListeners();
  }

  void setCustomer(Customer? c) {
    customer = c;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    discount = 0;
    amountPaid = 0;
    paymentMethod = PaymentMethod.cash;
    customer = null;
    notifyListeners();
  }

  /// Validates stock, generates the invoice number, saves the sale
  /// transactionally (stock deduction included), and returns the saved Sale
  /// (with its database id) ready for printing.
  Future<Sale> checkout({String? invoiceNumberOverride}) async {
    if (_lines.isEmpty) {
      throw StateError('Cannot checkout an empty cart');
    }
    for (final l in _lines) {
      if (l.type == SaleItemType.product && l.quantity > l.availableStock) {
        throw StateError('Not enough stock for "${l.name}" (have ${l.availableStock}, need ${l.quantity})');
      }
    }

    final invoiceNumber = invoiceNumberOverride ?? await _saleRepo.recordSaleInvoiceNumber();

    final saleItems = _lines
        .map((l) => SaleItem(
              itemType: l.type,
              itemId: l.itemId,
              itemName: l.name,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              purchasePrice: l.purchasePrice,
            ))
        .toList();

    final paidAmount = amountPaid > 0 ? amountPaid : grandTotal;

    final sale = Sale(
      invoiceNumber: invoiceNumber,
      customerId: customer?.id,
      customerName: customer?.name,
      subtotal: subtotal,
      discount: discount,
      grandTotal: grandTotal,
      amountPaid: paidAmount,
      changeAmount: (paidAmount - grandTotal).clamp(0, double.infinity),
      paymentMethod: paymentMethod,
      items: saleItems,
    );

    final id = await _saleRepo.recordSale(sale);
    clear();

    return Sale(
      id: id,
      invoiceNumber: sale.invoiceNumber,
      customerId: sale.customerId,
      customerName: sale.customerName,
      subtotal: sale.subtotal,
      discount: sale.discount,
      grandTotal: sale.grandTotal,
      amountPaid: sale.amountPaid,
      changeAmount: sale.changeAmount,
      paymentMethod: sale.paymentMethod,
      createdAt: sale.createdAt,
      items: sale.items,
    );
  }
}
