import 'package:flutter/widgets.dart';

import 'package:xayn_card_view/xayn_card_view/card_view.dart';

mixin CardViewListenersMixin on CardViewAnimatedState {
  @protected
  double chipSize = .0;

  int _dragStartCounter = 0;
  int _pendingPageOffset = 0;
  double _oldOffset = .0;
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

        final size = currentSize;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

        chipSize = (1.0 - size) * fullSize;

        final delta = scrollController!.offset - _realOffset;
        int pageOffset = _pendingPageOffset;

        if (delta > widget.deltaThreshold && index < widget.itemCount - 1) {
          pageOffset++;
        } else if (delta < -widget.deltaThreshold && index > 0) {
          pageOffset--;
        }

        pageOffset = pageOffset.clamp(-1, 1);

        final animationOffset =
            _oldOffset + pageOffset * fullSize - pageOffset * chipSize;
        final animationFactor =
            (animationOffset - scrollController!.position.pixels).abs() /
                fullSize;
        final currentDragCounter = _dragStartCounter;

        _pendingPageOffset = pageOffset;

        await scrollController!.animateTo(
          animationOffset,
          duration: widget.animateToSnapDuration * animationFactor,
          curve: widget.animateToSnapCurve,
        );

        if (currentDragCounter == _dragStartCounter) {
          _runPostAnimation(
            fullSize: fullSize,
            pageOffset: pageOffset,
          );
        }
      };

  void _confirmDragging(BoxConstraints constraints) {
    _dragStartCounter++;

    final size = currentSize;
    final fullSize =
        isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

    chipSize = (1.0 - size) * fullSize;

    final normalizedOffset = index == 0 ? .0 : fullSize - chipSize;

    _didStartDragging = _isDragActive = true;
    _oldOffset = normalizedOffset;
    _realOffset = scrollController!.offset;
  }

  void _runPostAnimation({
    required int pageOffset,
    required double fullSize,
  }) {
    if (_isDragActive) return;

    run() {
      index += pageOffset;
      _pendingPageOffset = 0;

      widget.controller?.index = index;

      final jumpToOffset = index > 0 ? chipSize : .0;

      scrollController!.jumpTo(index.clamp(0, 1) * fullSize - jumpToOffset);

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
