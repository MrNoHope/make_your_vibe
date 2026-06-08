import 'package:flutter_test/flutter_test.dart';
import 'package:android_code/main.dart';

void main() {
  testWidgets('Make Your Vibe app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MakeYourVibeApp());

    expect(find.text('Make Your Vibe'), findsOneWidget);
  });
}