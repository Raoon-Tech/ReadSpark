import 'package:flutter_test/flutter_test.dart';

import 'package:readspark/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is ReadSpark', () {
      expect(AppConstants.appName, 'ReadSpark');
    });

    test('supportedExtensions contains the four MVP formats', () {
      expect(
        AppConstants.supportedExtensions,
        containsAll(<String>['.pdf', '.docx', '.md', '.txt']),
      );
    });
  });
}
