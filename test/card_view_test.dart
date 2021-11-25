import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xayn_card_view/xayn_card_view.dart';

import 'utils.dart';

void main() {
  const data = ['a', 'b', 'c', 'd', 'e', 'f'];

  expectCardOfIndex(int index) {
    final max = data.length;
    if (index - 2 > 0) expect(findCardChild(data[index - 2]), findsNothing);
    if (index - 1 > 0) expect(findCardChild(data[index - 1]), findsOneWidget);
    expect(findCardChild(data[index]), findsOneWidget);
    if (index + 1 < max) expect(findCardChild(data[index + 1]), findsOneWidget);
    if (index + 2 < max) expect(findCardChild(data[index + 2]), findsNothing);
  }

  group('card view tests: ', () {
    testWidgets('Swipe Up', (WidgetTester tester) async {
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
        ),
      );

      expectCardOfIndex(0);
      await swipeUp(tester, findCardChild(data[0]));
      expectCardOfIndex(1);
      await swipeUp(tester, findCardChild(data[1]));
      expectCardOfIndex(2);
      await swipeUp(tester, findCardChild(data[2]));
      expectCardOfIndex(3);
    });

    testWidgets('Swipe Right', (WidgetTester tester) async {
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          scrollDirection: Axis.horizontal,
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
        ),
      );

      expectCardOfIndex(0);
      await swipeRight(tester, findCardChild(data[0]));
      expectCardOfIndex(1);
      await swipeRight(tester, findCardChild(data[1]));
      expectCardOfIndex(2);
      await swipeRight(tester, findCardChild(data[2]));
      expectCardOfIndex(3);
    });

    testWidgets('Secondary Item builder', (WidgetTester tester) async {
      const data2 = ['a2', 'b2', 'c2', 'd2', 'e2', 'f2'];

      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
          secondaryItemBuilder: (context, index) => getCardChild(data2[index]),
        ),
      );

      expect(findCardChild(data[0]), findsOneWidget);
      expect(findCardChild(data[1]), findsNothing);
      expect(findCardChild(data2[0]), findsNothing);

      await swipeUp(tester, findCardChild(data[0]));

      expect(findCardChild(data[1]), findsOneWidget);
      expect(findCardChild(data[2]), findsNothing);
      expect(findCardChild(data2[0]), findsOneWidget);
      expect(findCardChild(data2[1]), findsNothing);

      await swipeUp(tester, findCardChild(data[1]));

      expect(findCardChild(data[2]), findsOneWidget);
      expect(findCardChild(data[3]), findsNothing);
      expect(findCardChild(data2[1]), findsOneWidget);
      expect(findCardChild(data2[2]), findsNothing);
    });

    testWidgets('kDeltaThreshold', (WidgetTester tester) async {
      const double kDeltaThreshold = 50.0;
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
          deltaThreshold: kDeltaThreshold,
        ),
      );
      expectCardOfIndex(0);
      await swipeUp(tester, findCardChild(data[0]),
          threshold: kDeltaThreshold - 5);
      expectCardOfIndex(0);
      await swipeUp(tester, findCardChild(data[0]),
          threshold: kDeltaThreshold + 5);
      expectCardOfIndex(1);
    });

    testWidgets('onFinalIndex', (WidgetTester tester) async {
      int onFinalIndexCalled = 0;
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          itemCount: 2,
          itemBuilder: (context, index) => getCardChild(data[index]),
          onFinalIndex: () => onFinalIndexCalled++,
        ),
      );
      expect(onFinalIndexCalled, equals(0));
      await swipeUp(tester, findCardChild(data[0]));
      expect(onFinalIndexCalled, equals(1));
    });
  });
}
