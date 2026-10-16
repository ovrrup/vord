import 'package:flutter_test/flutter_test.dart';
import 'package:vord/main.dart';

void main() {
  testWidgets('Timer screen initial state smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VordApp());

    // Verify header title and initial timer display exist
    expect(find.text('VORD'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
  });
}
