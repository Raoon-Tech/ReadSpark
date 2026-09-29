import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:readspark/presentation/app/app.dart';

void main() {
  testWidgets('ReadSparkApp renders the library placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ReadSparkApp()));

    expect(find.text('ReadSpark'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
  });
}
