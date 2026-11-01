// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:habl/main.dart';

void main() {
  testWidgets('Unauthenticated users can open registration from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Main());

    expect(find.text('회원가입'), findsNothing);

    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('아직 계정이 없으신가요?'), findsOneWidget);
    await tester.ensureVisible(find.text('회원가입'));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('나에게 맞는 가입 유형을 골라주세요'), findsOneWidget);
    expect(find.text('동호회 회원'), findsOneWidget);
    expect(find.text('동호회 회장'), findsOneWidget);
  });
}
