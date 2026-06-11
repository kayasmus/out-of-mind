import 'package:flutter_test/flutter_test.dart';

import 'package:out_of_mind/main.dart';
import 'package:out_of_mind/screens/currency_selection_screen.dart';

void main() {
  testWidgets('shows onboarding when no currency is set',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(showCurrencySelection: true));

    expect(find.text('Welcome to Out of Mind'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('onboarding advances to next page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(showCurrencySelection: true));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Track how you feel when you spend'), findsOneWidget);
  });

  test('every currency has a unique code', () {
    final codes = currencies.map((c) => c['code']).toSet();
    expect(codes.length, currencies.length);
    expect(codes.contains(null), isFalse);
  });
}
