import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xayn_card_view/xayn_card_view.dart';

import 'utils.dart';

void main() {
  const data = ['a', 'b', 'c', 'd', 'e', 'f'];

  expectFirstCard() {
    expect(findCardChild(data[0]), findsOneWidget);
    expect(findCardChild(data[1]), findsOneWidget);
    expect(findCardChild(data[2]), findsNothing);
  }

  expectSecondCard() {
    expect(findCardChild(data[2]), findsOneWidget);
    expect(findCardChild(data[3]), findsNothing);
  }

  expectThirdCard() {
    expect(findCardChild(data[3]), findsOneWidget);
    expect(findCardChild(data[4]), findsNothing);
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

      expectFirstCard();
      await swipeUp(tester, findCardChild(data[0]));
      expectSecondCard();
      await swipeUp(tester, findCardChild(data[1]));
      expectThirdCard();
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

      expectFirstCard();
      await swipeRight(tester, findCardChild(data[0]));
      expectSecondCard();
      await swipeRight(tester, findCardChild(data[1]));
      expectThirdCard();
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
      expectFirstCard();
      await swipeUp(tester, findCardChild(data[0]),
          threshold: kDeltaThreshold - 5);
      expectFirstCard();
      await swipeUp(tester, findCardChild(data[0]),
          threshold: kDeltaThreshold + 5);
      expectSecondCard();
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
