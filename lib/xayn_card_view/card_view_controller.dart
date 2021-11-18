import 'package:flutter/widgets.dart';

class CardViewController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  set index(int value) {
    if (_index != value) {
      _index = value;

      notifyListeners();
    }
  }

  CardViewController({int startIndex = 0}) : _index = startIndex;
}
