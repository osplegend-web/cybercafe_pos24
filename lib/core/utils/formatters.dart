import 'package:intl/intl.dart';

class AppFormatters {
  static String money(num value, {String symbol = '₹'}) {
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: 2,
    );
    return f.format(value);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String date(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String dateShort(DateTime dt) {
    return DateFormat('dd-MM-yyyy').format(dt);
  }
}
