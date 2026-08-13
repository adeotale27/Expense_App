import 'package:intl/intl.dart';

class Money {
  const Money({required this.minorUnits, this.currencyCode = 'INR'});

  final int minorUnits;
  final String currencyCode;

  double get majorUnits => minorUnits / 100.0;

  factory Money.fromMajor(double major, {String currencyCode = 'INR'}) {
    return Money(
      minorUnits: (major * 100).round(),
      currencyCode: currencyCode,
    );
  }

  Money operator +(Money other) {
    assert(other.currencyCode == currencyCode);
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  String format({bool symbol = true}) {
    final format = NumberFormat.currency(
      locale: currencyCode == 'INR' ? 'en_IN' : 'en_US',
      symbol: symbol ? _symbol : '',
      decimalDigits: 0,
    );
    if (minorUnits % 100 == 0) {
      return format.format(majorUnits);
    }
    return NumberFormat.currency(
      locale: currencyCode == 'INR' ? 'en_IN' : 'en_US',
      symbol: symbol ? _symbol : '',
      decimalDigits: 2,
    ).format(majorUnits);
  }

  String get _symbol => switch (currencyCode) {
        'INR' => '₹',
        'USD' => '\$',
        'EUR' => '€',
        'GBP' => '£',
        _ => '$currencyCode ',
      };
}
