import 'package:flutter/widgets.dart';

enum JumpDirection { up, down }

class CardViewController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  set index(int value) {
    if (_index != value) {
      _index = value;

      notifyListeners();
    }
  }

  int _offset = 0;

  int get offset {
    final value = _offset;

    _offset = 0;

    return value;
  }

  CardViewController({int startIndex = 0}) : _index = startIndex;

  void jump(JumpDirection direction) {
    switch (direction) {
      case JumpDirection.up:
        _offset = -1;
        break;
      case JumpDirection.down:
        _offset = 1;
        break;
    }

    notifyListeners();
  }
}
