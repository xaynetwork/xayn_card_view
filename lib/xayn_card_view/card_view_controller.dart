import 'package:flutter/widgets.dart';

enum JumpDirection { up, down }
enum JumpBehavior { direct, animated }

class CardViewController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  /// Change index immediately, without animation.
  set index(int value) {
    if (_index != value) {
      _index = value;

      notifyListeners();
    }
  }

  JumpBehavior jumpBehavior = JumpBehavior.direct;

  int _offset = 0;

  CardViewController({int startIndex = 0}) : _index = startIndex;

  /// Change index using an animation.
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

  /// Gets the next requested [jump] offset,
  /// and then internally resets the jump offset back to 0 (no jump)
  int getNextOffsetAndReset() {
    final value = _offset;

    _offset = 0;

    return value;
  }
}
