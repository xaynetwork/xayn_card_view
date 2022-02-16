import 'package:flutter/widgets.dart';

import 'package:xayn_card_view/xayn_card_view/card_view.dart';

mixin CardViewListenersMixin on CardViewAnimatedState {
  @protected
  double chipSize = .0;

  double _realOffset = .0;
  bool _didStartDragging = false;
  bool _isDragActive = false;

  @protected
  bool get isVerticalScroll => widget.scrollDirection == Axis.vertical;

  @protected
  void Function(PointerDownEvent?) onDragStart(BoxConstraints constraints) =>
      (PointerDownEvent? event) {
        if (widget.disableGestures) return;

        _confirmDragging(constraints);
      };

  @protected
  void Function(PointerMoveEvent?) onDragUpdate(BoxConstraints constraints) =>
      (PointerMoveEvent? event) {
        if (widget.disableGestures) return;

        if (!_didStartDragging) {
          _confirmDragging(constraints);
        }
      };

  @protected
  void Function(PointerUpEvent?) onDragEnd(BoxConstraints constraints) =>
      (PointerUpEvent? event) async {
        if (widget.disableGestures) return;

        _isDragActive = false;

        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

        chipSize = (1.0 - currentSize) * fullSize;

        final delta = scrollController!.offset - _realOffset;

        if (delta == .0) return;

        int pageOffset = 0;

        if (delta > widget.deltaThreshold && index < widget.itemCount - 1) {
          pageOffset++;
        } else if (delta < -widget.deltaThreshold && index > 0) {
          pageOffset--;
        }

        pageOffset = pageOffset.clamp(-1, 1);

        jump(pageOffset: pageOffset);
      };

  Future<void> jump({required int pageOffset}) async {
    final constraints = lastKnownConstraints;

    if (constraints == null) return;

    final nextIndex = index + pageOffset;
    final fullSize =
        isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
    var targetPosition =
        scrollController!.offset - pageOffset * currentSize * fullSize;

    if ((pageOffset >= 0 && nextIndex <= 1) ||
        (pageOffset < 0 && nextIndex < 1)) {
      targetPosition = scrollController!.offset;
    }

    _updateNow(
      targetPosition: targetPosition,
      pageOffset: pageOffset,
    );

    final jumpOffset = index > 0 ? chipSize : .0;
    final animationOffset = index.clamp(0, 1) * fullSize - jumpOffset;

    await scrollController!.animateTo(
      animationOffset,
      duration: widget.animateToSnapDuration,
      curve: widget.animateToSnapCurve,
    );
  }

  void _confirmDragging(BoxConstraints constraints) {
    final size = currentSize;
    final fullSize =
        isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

    chipSize = (1.0 - size) * fullSize;

    _didStartDragging = _isDragActive = true;
    _realOffset = scrollController!.offset;
  }

  void _updateNow({
    required int pageOffset,
    required double targetPosition,
  }) {
    if (_isDragActive) return;

    run() {
      index += pageOffset;

      widget.controller?.index = index;

      scrollController!.jumpTo(targetPosition);

      if (pageOffset != 0) {
        widget.onIndexChanged?.call(index);
      }

      if (widget.itemCount > 0 && index == widget.itemCount - 1) {
        widget.onFinalIndex?.call();
      }
    }

    pageOffset != 0 ? setState(run) : run();
  }
}
