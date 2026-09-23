enum PaymentMethod { cash, upi, card, other }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Item type stored inside a sale_item row - lets one bill mix
/// stationery products and cyber-cafe services.
enum SaleItemType { product, service }

extension SaleItemTypeX on SaleItemType {
  static SaleItemType fromString(String value) {
    return SaleItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SaleItemType.product,
    );
  }
}

class DefaultData {
  static const List<String> defaultCategories = [
    'Stationery',
    'Electronics',
    'Registers & Books',
    'Printing Supplies',
    'Miscellaneous',
  ];

  static const List<String> defaultServices = [
    'Printing (B/W)',
    'Printing (Color)',
    'Photocopy',
    'Scanning',
    'Lamination',
    'Passport Photo',
    'Online Form Filling',
    'Typing',
    'Internet/Computer Usage',
    'Other Service',
  ];

  static const List<String> expenseCategories = [
    'Electricity',
    'Internet',
    'Stationery Purchase',
    'Rent',
    'Maintenance',
    'Salary',
    'Other',
  ];

  static const List<String> units = [
    'pcs',
    'box',
    'ream',
    'pack',
    'kg',
    'litre',
    'meter',
    'other',
  ];
}

class AppSettingsKeys {
  static const shopName = 'shop_name';
  static const shopAddress = 'shop_address';
  static const shopPhone = 'shop_phone';
  static const gstin = 'gstin';
  static const currencySymbol = 'currency_symbol';
  static const invoicePrefix = 'invoice_prefix';
  static const lastInvoiceNumber = 'last_invoice_number';
  static const themeMode = 'theme_mode'; // light / dark / system
  static const printerName = 'printer_name';
}
