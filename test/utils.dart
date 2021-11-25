import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future standaloneWidgetSetup(WidgetTester tester,
    {required Widget widget}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    ),
  );
  await tester.pump();
}

String getCardChildKeyName(String data) => 'card_child_' + data;

Widget getCardChild(String data) => Text(
      data,
      key: Key(getCardChildKeyName(data)),
    );

Finder findCardChild(String data) => find.byKey(Key(getCardChildKeyName(data)));

Future<void> swipeUp(WidgetTester tester, Finder child,
    {double threshold = 800}) async {
  await tester.runAsync(() async {
    await tester.drag(child, Offset(0, -threshold));
    await tester.pumpAndSettle();
  });
}

Future<void> swipeDown(WidgetTester tester, Finder child) async {
  await tester.runAsync(() async {
    await tester.drag(child, const Offset(0, 800));
    await tester.idle();
    await tester.pumpAndSettle();
  });
}

Future<void> swipeRight(WidgetTester tester, Finder child) async {
  await tester.runAsync(() async {
    await tester.drag(child, const Offset(-800, 0));
    await tester.pumpAndSettle();
  });
}
