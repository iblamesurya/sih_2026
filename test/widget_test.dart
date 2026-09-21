import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/main.dart';

void main() {
  testWidgets('PrawnGuardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PrawnGuardApp()));
    expect(find.byType(PrawnGuardApp), findsOneWidget);
  });
}
