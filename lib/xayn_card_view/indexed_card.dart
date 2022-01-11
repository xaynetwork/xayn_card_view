import 'package:flutter/widgets.dart';

class IndexedCard {
  final int index;
  final Widget widget;

  const IndexedCard({
    required this.index,
    required this.widget,
  });
}