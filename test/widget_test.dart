import 'package:flutter_test/flutter_test.dart';
import 'package:vord/main.dart';

void main() {
  testWidgets('Onboarding flow display and completion test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: true));

    // Verify first onboarding slide
    expect(find.text('VORD'), findsOneWidget);
    expect(find.text('01 / PHILOSOPHY'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);

    // Tap NEXT to go to slide 2
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('02 / GESTURES'), findsOneWidget);

    // Tap NEXT to go to slide 3
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('03 / CADENCE'), findsOneWidget);
    expect(find.text('BEGIN'), findsOneWidget);

    // Tap BEGIN to enter timer screen
    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
  });

  testWidgets('Onboarding skip button test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: true));

    // Tap SKIP
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    // Verify immediately on TimerScreen
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('Timer screen initial state smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: false));

    // Verify header title and initial timer display exist
    expect(find.text('VORD'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
  });

  testWidgets('Mode selector switches between Focus and Break', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: false));

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
    await tester.pumpWidget(const VordApp(initialShowOnboarding: false));

    // Tap history button
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    // Verify history sheet contents
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.textContaining('completed focus'), findsOneWidget);
    expect(find.text('GESTURE GUIDE'), findsOneWidget);
  });
}
