import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shr/main.dart';

void main() {
  testWidgets('MultiFamilyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MultiFamilyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MultiFamilyApp), findsOneWidget);
  });
}
