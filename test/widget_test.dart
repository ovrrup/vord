import 'package:flutter_test/flutter_test.dart';
import 'package:vord/main.dart';

void main() {
  testWidgets('Timer screen initial state smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp());

    // Verify header title and initial timer display exist
    expect(find.text('VORD'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
  });

  testWidgets('Mode selector switches between Focus and Break', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp());

    // Tap Short Break
    await tester.tap(find.text('Short Break'));
    await tester.pumpAndSettle();

    // Verify timer changes to 05:00
    expect(find.text('05:00'), findsOneWidget);

    // Tap Long Break
    await tester.tap(find.text('Long Break'));
    await tester.pumpAndSettle();

    // Verify timer changes to 15:00
    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('Opening session history bottom sheet', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp());

    // Tap history button
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    // Verify history sheet contents
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.textContaining('completed focus'), findsOneWidget);
  });
}
