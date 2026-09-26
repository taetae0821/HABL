// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:habl/main.dart';

void main() {
  testWidgets('Registration screen is shown', (WidgetTester tester) async {
    await tester.pumpWidget(const Main());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('가입 방법을 선택해주세요'), findsOneWidget);
    expect(find.text('이메일로 가입하기'), findsOneWidget);
  });
}
