import 'package:flutter_test/flutter_test.dart';

import 'package:mucsic/main.dart';

void main() {
  testWidgets('Mucsic home renders music app shell', (tester) async {
    await tester.pumpWidget(const MucsicApp());

    expect(find.text('Mucsic'), findsOneWidget);
    expect(find.text('Vietnamese music videos from YouTube'), findsOneWidget);
    expect(find.text('Search for a song'), findsOneWidget);
  });
}
