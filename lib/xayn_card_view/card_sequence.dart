import 'package:flutter/widgets.dart';

enum Direction {
  horizontal,
  vertical,
}

class CardSequence extends StatelessWidget {
  final Direction direction;
  final Iterable<Widget> children;
  final double chipSize;
  final Size cardSize;

  const CardSequence({
    Key? key,
    required this.direction,
    required this.children,
    required this.chipSize,
    required this.cardSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (direction) {
      case Direction.vertical:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...children,
            SizedBox(
              height: chipSize,
            )
          ],
        );
      case Direction.horizontal:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...children,
            SizedBox(
              width: chipSize,
            )
          ],
        );
    }
  }
}
