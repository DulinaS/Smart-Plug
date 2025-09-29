import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'en_LK',
    symbol: '',
    decimalDigits: 2,
  );

  static final _numberFormatter = NumberFormat('#,##0.0');
  static final _integerFormatter = NumberFormat('#,##0');

  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String power(double watts) {
    if (watts >= 1000) {
      return '${(watts / 1000).toStringAsFixed(1)}k';
    }
    return watts.toStringAsFixed(1);
  }

  static String energy(double kWh) {
    return _numberFormatter.format(kWh);
  }

  static String voltage(double volts) {
    return '${volts.toStringAsFixed(1)}V';
  }

  static String current(double amps) {
    return '${amps.toStringAsFixed(2)}A';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  static String time(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String date(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }
}
