import 'package:flutter/widgets.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_child.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_controller.dart';

const double kCardSizeFraction = .9;
const double kItemSpacing = 12.0;
const Duration kAnimateToSnapDuration = Duration(milliseconds: 260);
const Axis kScrollDirection = Axis.vertical;
const BorderRadius kClipBorderRadius = BorderRadius.all(
  Radius.circular(12.0),
);

class CardView extends StatefulWidget {
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

class CardViewState extends State<CardView> {
  final Map<int, CardViewChild> _builtWidgets = <int, CardViewChild>{};
  late final ScrollController _scrollController;
  int _index = 0;
  int _topBuiltIndex = 0;
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
    _builtWidgets.clear();

    widget.controller?.removeListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CardView oldWidget) {
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
    final secondaryItemBuilder =
        widget.secondaryItemBuilder ?? widget.itemBuilder;

    buildCard({
      required int index,
      required IndexedWidgetBuilder builder,
      required bool shouldRenderOffstage,
      double? width,
      double? height,
    }) =>
        _builtWidgets[index] = CardViewChild(
          key: ValueKey(index),
          child: builder(context, index),
          width: width,
          height: height,
          isVerticalScroll: isVerticalScroll,
          clipBorderRadius: widget.clipBorderRadius,
          itemSpacing: widget.itemSpacing,
          shouldRenderOffstage: shouldRenderOffstage,
          shouldDispose: false,
        );

    return LayoutBuilder(builder: (context, constraints) {
      final fullSize =
          isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
      final cardSize = widget.size * fullSize;
      final w = isVerticalScroll ? null : cardSize;
      final h = isVerticalScroll ? cardSize : null;

      if (widget.itemCount > 0) {
        buildCard(
          index: _index,
          builder: widget.itemBuilder,
          shouldRenderOffstage: false,
          width: w,
          height: h,
        );
      }

      if (_index > 0) {
        buildCard(
          index: _index - 1,
          builder: secondaryItemBuilder,
          shouldRenderOffstage: false,
          width: w,
          height: h,
        );
      }

      if (_index < widget.itemCount - 1) {
        buildCard(
          index: _index + 1,
          builder: secondaryItemBuilder,
          shouldRenderOffstage: false,
          width: w,
          height: h,
        );
      }

      _topBuiltIndex = _index + 1;

      for (var i = 0; i <= _topBuiltIndex; i++) {
        if (i < _index - 1 || i > _index + 1) {
          buildCard(
            index: i,
            builder: secondaryItemBuilder,
            shouldRenderOffstage: true,
            width: w,
            height: h,
          );
        }
      }

      final rowOrColumnChild = isVerticalScroll
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _builtWidgets.values.toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _builtWidgets.values.toList(),
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
        final threshold = fullSize / 5;
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
