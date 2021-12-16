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
const double kDeltaThreshold = 50.0;
const EdgeInsets kPadding = EdgeInsets.zero;

typedef IndexChangedCallback = void Function(int index);

class CardView extends ImplicitlyAnimatedWidget {
  final int itemCount;
  final double itemSpacing;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? secondaryItemBuilder;
  final CardViewController? controller;
  final double size;
  final BorderRadius clipBorderRadius;
  final Duration animateToSnapDuration;
  final Axis scrollDirection;
  final double deltaThreshold;
  final VoidCallback? onFinalIndex;
  final IndexChangedCallback? onIndexChanged;
  final EdgeInsets padding;
  final bool disableGestures;

  const CardView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required Duration animationDuration,
    Curve animationCurve = Curves.linear,
    this.secondaryItemBuilder,
    this.controller,
    this.size = kCardSizeFraction,
    this.itemSpacing = kItemSpacing,
    this.clipBorderRadius = kClipBorderRadius,
    this.animateToSnapDuration = kAnimateToSnapDuration,
    this.scrollDirection = kScrollDirection,
    this.deltaThreshold = kDeltaThreshold,
    this.onFinalIndex,
    this.onIndexChanged,
    this.padding = kPadding,
    this.disableGestures = false,
  }) : super(
          key: key,
          duration: animationDuration,
          curve: animationCurve,
        );

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      CardViewState();
}

class CardViewState extends AnimatedWidgetBaseState<CardView> {
  final Map<int, CardViewChild> _builtWidgets = <int, CardViewChild>{};
  late final ScrollController _scrollController;
  bool _isAbsorbingPointer = false;
  int _index = 0;
  int _topBuiltIndex = 0;
  double _oldOffset = .0;
  double _chipSize = .0;
  bool _shouldUpdateScrollPosition = false;
  bool _didStartDragging = false;

  bool get isVerticalScroll => widget.scrollDirection == Axis.vertical;

  Tween<double>? _size;
  Tween<double>? _itemSpacing;
  Tween<EdgeInsets>? _padding;
  Tween<BorderRadius>? _clipBorderRadius;

  @override
  void initState() {
    super.initState();

    final controller = widget.controller;

    if (controller != null) {
      assert(controller.index < widget.itemCount,
          'Controller index is out of bound. index should be less than itemCount.');
      _index = controller.index;

      controller.addListener(_onControllerChanged);
    }

    _scrollController = ScrollController(keepScrollOffset: false);

    widget.onIndexChanged?.call(_index);

    super.controller.addListener(() {
      _shouldUpdateScrollPosition = true;
    });
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
    _builtWidgets.clear();

    widget.controller?.removeListener(_onControllerChanged);
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _size = visitor(_size, widget.size,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;

    _itemSpacing = visitor(_itemSpacing, widget.itemSpacing,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;

    _padding = visitor(_padding, widget.padding,
            (dynamic value) => Tween<EdgeInsets>(begin: value as EdgeInsets))
        as Tween<EdgeInsets>?;

    _clipBorderRadius = visitor(
            _clipBorderRadius,
            widget.clipBorderRadius,
            (dynamic value) =>
                Tween<BorderRadius>(begin: value as BorderRadius))
        as Tween<BorderRadius>?;
  }

  @override
  void didUpdateWidget(CardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemCount != widget.itemCount) {
      _index = widget.itemCount > 0 ? _index.clamp(0, widget.itemCount - 1) : 0;

      widget.controller?.index = _index;
    }

    if (oldWidget.scrollDirection != widget.scrollDirection ||
        oldWidget.size != widget.size) {
      _shouldUpdateScrollPosition = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = (_padding?.evaluate(animation) ?? widget.padding).clamp(
      EdgeInsets.zero,
      const EdgeInsets.all(double.maxFinite),
    );
    final clipBorderRadius =
        (_clipBorderRadius?.evaluate(animation) ?? widget.clipBorderRadius)
            .clamp(
      Radius.zero,
      const Radius.circular(double.maxFinite),
    );
    final itemSpacing =
        (_itemSpacing?.evaluate(animation) ?? widget.itemSpacing).clamp(
      .0,
      double.maxFinite,
    );
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
          clipBorderRadius: clipBorderRadius,
          itemSpacing: itemSpacing,
          shouldRenderOffstage: shouldRenderOffstage,
          shouldDispose: false,
        );

    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = _size?.evaluate(animation) ?? widget.size;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
        final cardSize = size * fullSize;
        final w = isVerticalScroll ? constraints.maxWidth : cardSize;
        final h = isVerticalScroll ? cardSize : constraints.maxHeight;

        if (_shouldUpdateScrollPosition) {
          _shouldUpdateScrollPosition = false;

          final fullSize =
              isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

          _chipSize = ((1.0 - size) * fullSize).clamp(.0, fullSize);

          final jumpToOffset = _index > 0 ? _chipSize : .0;

          _scrollController
              .jumpTo(_index.clamp(0, 1) * fullSize - jumpToOffset);
        }

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
                children: [
                  ..._builtWidgets.values,
                  SizedBox(
                    height: _chipSize,
                  )
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._builtWidgets.values,
                  SizedBox(
                    width: _chipSize,
                  )
                ],
              );

        final fraction = itemSpacing * .5;
        final singleScrollChild = Padding(
          padding: EdgeInsets.only(
            top: isVerticalScroll ? fraction : .0,
            bottom: isVerticalScroll ? fraction : .0,
            left: isVerticalScroll ? .0 : fraction,
            right: isVerticalScroll ? .0 : fraction,
          ),
          child: rowOrColumnChild,
        );

        return AbsorbPointer(
          absorbing: _isAbsorbingPointer,
          child: Listener(
            onPointerDown: _onDragStart,
            onPointerMove: _onDragUpdate,
            onPointerUp: _onDragEnd(constraints),
            child: ScrollConfiguration(
              behavior: const NoOverscrollBehavior(),
              child: SingleChildScrollView(
                physics: widget.disableGestures
                    ? const NeverScrollableScrollPhysics()
                    : null,
                scrollDirection: widget.scrollDirection,
                controller: _scrollController,
                child: singleScrollChild,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _onControllerChanged() {
    final controller = widget.controller!;

    if (_index != controller.index) {
      setState(() {
        assert(controller.index < widget.itemCount,
            'Controller index is out of bound. index should be less than itemCount.');
        _index = controller.index;
        widget.onIndexChanged?.call(_index);
      });
    }
  }

  void _onDragStart(PointerDownEvent? event) {
    if (widget.disableGestures) return;

    _didStartDragging = true;
    _oldOffset = _scrollController.offset;
  }

  void _onDragUpdate(PointerMoveEvent? event) {
    if (widget.disableGestures) return;

    if (!_didStartDragging) {
      _didStartDragging = true;
      _oldOffset = _scrollController.offset;
    }
  }

  void Function(PointerUpEvent?) _onDragEnd(BoxConstraints constraints) =>
      (PointerUpEvent? event) async {
        if (widget.disableGestures) return;

        final size = _size?.evaluate(animation) ?? widget.size;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

        _chipSize = (1.0 - size) * fullSize;

        final delta = _scrollController.offset - _oldOffset;
        int pageOffset = 0;

        if (delta > widget.deltaThreshold && _index < widget.itemCount - 1) {
          pageOffset++;
        } else if (delta < -widget.deltaThreshold && _index > 0) {
          pageOffset--;
        }

        setState(() => _isAbsorbingPointer = true);

        final animationOffset =
            _oldOffset + pageOffset * fullSize - pageOffset * _chipSize;

        await _scrollController.animateTo(
          animationOffset,
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

          if (pageOffset != 0) {
            widget.onIndexChanged?.call(_index);
          }

          if (widget.itemCount > 0 && _index == widget.itemCount - 1) {
            widget.onFinalIndex?.call();
          }
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

extension _BorderRadiusExtension on BorderRadius {
  BorderRadius clamp(Radius min, Radius max) {
    return BorderRadius.only(
      bottomRight: Radius.elliptical(
          bottomRight.x.clamp(min.x, max.x), bottomRight.y.clamp(min.y, max.y)),
      bottomLeft: Radius.elliptical(
          bottomLeft.x.clamp(min.x, max.x), bottomLeft.y.clamp(min.y, max.y)),
      topRight: Radius.elliptical(
          topRight.x.clamp(min.x, max.x), topRight.y.clamp(min.y, max.y)),
      topLeft: Radius.elliptical(
          topLeft.x.clamp(min.x, max.x), topLeft.y.clamp(min.y, max.y)),
    );
  }
}
