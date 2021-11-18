import 'package:flutter/widgets.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_controller.dart';

const double kCardSizeFraction = .9;
const double kItemSpacing = 12.0;
const Duration kAnimateToSnapDuration = Duration(milliseconds: 260);
const Axis kScrollDirection = Axis.vertical;
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
  final Axis scrollDirection;

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
    this.scrollDirection = kScrollDirection,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CardViewState();
}

class CardViewState<T> extends State<CardView<T>> {
  final Map<int, Widget> _builtPrimaryWidgets = <int, Widget>{};
  final Map<int, Widget> _builtSecondaryWidgets = <int, Widget>{};
  late final ScrollController _scrollController;
  int _index = 0;
  double _oldOffset = .0;
  double _chipSize = .0;
  bool _isAbsorbingPointer = false;

  bool get isVerticalScroll => widget.scrollDirection == Axis.vertical;

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

    _builtPrimaryWidgets.clear();
    _builtSecondaryWidgets.clear();
  }

  @override
  void didUpdateWidget(CardView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemCount != widget.itemCount) {
      final wasAtEnd = _index == oldWidget.itemCount - 1;
      final hasMoreItemsNow = widget.itemCount > oldWidget.itemCount;

      _index = widget.itemCount > 0 ? _index.clamp(0, widget.itemCount - 1) : 0;

      widget.controller?.index = _index;

      if (wasAtEnd && hasMoreItemsNow) {
        _scrollController.animateTo(
          _scrollController.offset + _chipSize,
          duration: widget.animateToSnapDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBuilder = widget.itemBuilder;
    final secondaryItemBuilder = widget.secondaryItemBuilder ?? primaryBuilder;

    return LayoutBuilder(builder: (context, constraints) {
      final cardPrimary =
          widget.itemCount > 0 ? primaryBuilder(context, _index) : null;
      final cardBefore =
          _index > 0 ? secondaryItemBuilder(context, _index - 1) : null;
      final cardAfter = _index < widget.itemCount - 1
          ? secondaryItemBuilder(context, _index + 1)
          : null;
      final fullSize =
          isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
      final cardSize = widget.size * fullSize;
      final w = isVerticalScroll ? null : cardSize;
      final h = isVerticalScroll ? cardSize : null;

      constraintToSize(Widget child) => SizedBox(
            width: w,
            height: h,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isVerticalScroll ? widget.itemSpacing : .0,
                right: isVerticalScroll ? .0 : widget.itemSpacing,
              ),
              child: ClipRRect(
                child: child,
                borderRadius: widget.clipBorderRadius,
              ),
            ),
          );

      final children = [
        if (cardBefore != null) constraintToSize(cardBefore),
        if (cardPrimary != null) constraintToSize(cardPrimary),
        if (cardAfter != null) constraintToSize(cardAfter),
      ];
      final rowOrColumnChild = isVerticalScroll
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            );

      final singleScrollChild = Listener(
        onPointerDown: _onDragStart,
        onPointerUp: _onDragEnd(constraints),
        child: Padding(
          padding: EdgeInsets.only(
            top: isVerticalScroll ? widget.itemSpacing : .0,
            left: isVerticalScroll ? .0 : widget.itemSpacing,
          ),
          child: rowOrColumnChild,
        ),
      );

      return AbsorbPointer(
        absorbing: _isAbsorbingPointer,
        child: ScrollConfiguration(
          behavior: const NoOverscrollBehavior(),
          child: SingleChildScrollView(
            scrollDirection: widget.scrollDirection,
            controller: _scrollController,
            child: singleScrollChild,
          ),
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
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

        _chipSize = (1.0 - widget.size) * fullSize;

        final delta = _scrollController.offset - _oldOffset;
        final threshold = fullSize / 3;
        int pageOffset = 0;

        if (delta > threshold) {
          pageOffset++;
        } else if (delta < -threshold) {
          pageOffset--;
        }

        setState(() => _isAbsorbingPointer = true);

        await _scrollController.animateTo(
          _oldOffset + pageOffset * fullSize,
          duration: widget.animateToSnapDuration,
          curve: Curves.easeOut,
        );

        setState(() {
          _index += pageOffset;
          _isAbsorbingPointer = false;

          widget.controller?.index = _index;

          final jumpToOffset = _index > 0 ? _chipSize : .0;

          _scrollController
              .jumpTo(_index.clamp(0, 1) * fullSize - jumpToOffset);
        });
      };
}

class NoOverscrollBehavior extends ScrollBehavior {
  const NoOverscrollBehavior();

  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
