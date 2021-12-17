import 'package:flutter_test/flutter_test.dart';
import 'package:xayn_card_view/xayn_card_view.dart';

import 'utils.dart';

void main() {
  const data = ['a', 'b', 'c', 'd', 'e', 'f'];
  const startIndex = 2;
  late CardViewController _controller;

  setUp(() {
    _controller = CardViewController(startIndex: startIndex);
  });

  group('card view controller tests: ', () {
    testWidgets('Start index', (WidgetTester tester) async {
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          animationDuration: const Duration(seconds: 1),
          controller: _controller,
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
        ),
      );
      expect(findCardChild(data[startIndex - 2]), findsNothing);
      expect(findCardChild(data[startIndex - 1]), findsOneWidget);
      expect(findCardChild(data[startIndex]), findsOneWidget);
      expect(findCardChild(data[startIndex + 1]), findsOneWidget);
      expect(findCardChild(data[startIndex + 2]), findsNothing);
    });

    testWidgets('Observe index change', (WidgetTester tester) async {
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          animationDuration: const Duration(seconds: 1),
          controller: _controller,
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
        ),
      );
      expect(_controller.index, startIndex);
      await swipeUp(tester, findCardChild(data[startIndex]));
      expect(_controller.index, startIndex + 1);
      await swipeDown(tester, findCardChild(data[startIndex + 1]));
      expect(_controller.index, startIndex);
    });

    testWidgets('Change index', (WidgetTester tester) async {
      await standaloneWidgetSetup(
        tester,
        widget: CardView(
          animationDuration: const Duration(seconds: 1),
          controller: _controller,
          itemCount: data.length,
          itemBuilder: (context, index) => getCardChild(data[index]),
        ),
      );
      _controller.index = startIndex + 1;
      await tester.pump();
      expect(findCardChild(data[startIndex + 1]), findsOneWidget);
      expect(findCardChild(data[startIndex + 2]), findsOneWidget);
      expect(findCardChild(data[startIndex + 3]), findsNothing);
    });
  });
}
