import 'package:flutter_test/flutter_test.dart';
import 'package:make_your_vibe/app.dart';

void main() {
  testWidgets('App starts', (tester) async {
    await tester.pumpWidget(const MakeYourVibeApp());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Make Your Vibe'), findsWidgets);
  });
}
