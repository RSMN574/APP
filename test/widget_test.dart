import 'package:com.rsmn574.app/features/startup/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding exposes primary navigation controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(onCompleted: () async {}),
      ),
    );

    expect(find.textContaining('公共運輸'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('略過'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.textContaining('即時掌握'), findsOneWidget);
  });
}
