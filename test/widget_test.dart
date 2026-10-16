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

    // Tap BEGIN to enter timer screen with dual rotating dial
    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();
    expect(find.text('25'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('SEC'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
  });

  testWidgets('Onboarding skip button test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: true));

    // Tap SKIP
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    // Verify immediately on TimerScreen with dual rotating dial
    expect(find.text('25'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('SEC'), findsOneWidget);
  });

  testWidgets('Timer screen initial state smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: false));

    // Verify header title, dual dials, and controls exist
    expect(find.text('VORD'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    expect(find.text('SEC'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
  });

  testWidgets('Mode selector switches between Focus and Break', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(initialShowOnboarding: false));

    // Tap Short Break
    await tester.tap(find.text('Short Break'));
    await tester.pumpAndSettle();

    // Verify minutes dial changes to 05
    expect(find.text('05'), findsOneWidget);

    // Tap Long Break
    await tester.tap(find.text('Long Break'));
    await tester.pumpAndSettle();

    // Verify minutes dial changes to 15
    expect(find.text('15'), findsOneWidget);
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
