import 'package:flutter/widgets.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_controller.dart';

const double kCardSizeFraction = .9;
const double kItemSpacing = 12.0;
const Duration kAnimateToSnapDuration = Duration(milliseconds: 200);
const BorderRadius kClipBorderRadius = BorderRadius.all(
  Radius.circular(12.0),
);

class CardView<T> extends StatefulWidget {
  final int itemCount;
  final double itemSpacing;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? secondaryItemBuilder;
  final CardViewController? controller;
  final double size;
  final BorderRadius clipBorderRadius;
  final Duration animateToSnapDuration;

  const CardView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.secondaryItemBuilder,
    this.controller,
    this.size = kCardSizeFraction,
    this.itemSpacing = kItemSpacing,
    this.clipBorderRadius = kClipBorderRadius,
    this.animateToSnapDuration = kAnimateToSnapDuration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CardViewState();
}

class CardViewState<T> extends State<CardView<T>> {
  late final ScrollController _scrollController;
  int _index = 0;
  double _oldOffset = .0;
  bool _isAbsorbingPointer = false;

  @override
  void initState() {
    super.initState();

    final controller = widget.controller;

    if (controller != null) {
      _index = controller.index;

      controller.addListener(_onControllerChanged);
    }

    _scrollController = ScrollController(keepScrollOffset: false);
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();

    widget.controller?.removeListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CardView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemCount != widget.itemCount) {
      _index = widget.itemCount > 0 ? _index.clamp(0, widget.itemCount - 1) : 0;

      widget.controller?.index = _index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBuilder = widget.itemBuilder;
    final secondaryItemBuilder = widget.secondaryItemBuilder ?? primaryBuilder;

    return LayoutBuilder(builder: (context, constraints) {
      final primaryCard =
          widget.itemCount > 0 ? primaryBuilder(context, _index) : null;
      final cardAbove =
          _index > 0 ? secondaryItemBuilder(context, _index - 1) : null;
      final cardBelow = _index < widget.itemCount - 1
          ? secondaryItemBuilder(context, _index + 1)
          : null;
      final cardSize = widget.size * constraints.maxHeight;

      constraintToSize(Widget child) => SizedBox(
            height: cardSize,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.itemSpacing,
              ),
              child: ClipRRect(
                child: child,
                borderRadius: widget.clipBorderRadius,
              ),
            ),
          );

      final rowOrColumnChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (cardAbove != null) constraintToSize(cardAbove),
          if (primaryCard != null) constraintToSize(primaryCard),
          if (cardBelow != null) constraintToSize(cardBelow),
        ],
      );

      final singleScrollChild = Listener(
        onPointerDown: _onDragStart,
        onPointerUp: _onDragEnd(constraints),
        child: Padding(
          padding: EdgeInsets.only(top: widget.itemSpacing),
          child: rowOrColumnChild,
        ),
      );

      return AbsorbPointer(
        absorbing: _isAbsorbingPointer,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: singleScrollChild,
        ),
      );
    });
  }

  void _onControllerChanged() {
    final controller = widget.controller!;

    if (_index != controller.index) {
      setState(() {
        _index = controller.index;
      });
    }
  }

  void _onDragStart(PointerDownEvent? event) {
    _oldOffset = _scrollController.offset;
  }

  void Function(PointerUpEvent?) _onDragEnd(BoxConstraints constraints) =>
      (PointerUpEvent? event) async {
        final chipSize = (1.0 - widget.size) * constraints.maxHeight;
        final delta = _scrollController.offset - _oldOffset;
        final threshold = constraints.maxHeight / 3;
        int pageOffset = 0;

        if (delta > threshold) {
          pageOffset++;
        } else if (delta < -threshold) {
          pageOffset--;
        }

        setState(() => _isAbsorbingPointer = true);

        await _scrollController.animateTo(
          _oldOffset + pageOffset * constraints.maxHeight - 2 * chipSize,
          duration: widget.animateToSnapDuration,
          curve: Curves.easeOut,
        );

        setState(() {
          _index += pageOffset;
          _isAbsorbingPointer = false;

          widget.controller?.index = _index;

          final jumpToOffset = _index > 0 ? chipSize : .0;

          _scrollController.jumpTo(
              _index.clamp(0, 1) * constraints.maxHeight - jumpToOffset);
        });
      };
}
