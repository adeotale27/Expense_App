import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/constants/app_constants.dart';

void main() {
  test('app name and version file contract', () {
    expect(AppConstants.appName, 'SpendPing');
    expect(AppConstants.defaultCurrency, 'INR');
  });
}
