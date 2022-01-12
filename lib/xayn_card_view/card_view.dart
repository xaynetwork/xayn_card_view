import 'package:flutter/widgets.dart';
import 'package:xayn_card_view/xayn_card_view/card_sequence.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_child.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_controller.dart';
import 'package:xayn_card_view/xayn_card_view/indexed_card.dart';

const double _kCardSizeFraction = .9;
const double _kItemSpacing = 12.0;
const Duration _kAnimateToSnapDuration = Duration(milliseconds: 500);
const Curve _kAnimateToSnapCurve = Curves.linearToEaseOut;
const Axis _kScrollDirection = Axis.vertical;
const BorderRadius _kClipBorderRadius = BorderRadius.all(
  Radius.circular(12.0),
);
const double _kDeltaThreshold = 50.0;
const EdgeInsets _kPadding = EdgeInsets.zero;

typedef IndexChangedCallback = void Function(int index);
typedef BoxBorderBuilder = BoxBorder? Function(int index);

class CardView extends ImplicitlyAnimatedWidget {
  final int itemCount;
  final double itemSpacing;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder secondaryItemBuilder;
  final CardViewController? controller;
  final double size;
  final BoxBorderBuilder borderBuilder;
  final BorderRadius clipBorderRadius;
  final Duration animateToSnapDuration;
  final Curve animateToSnapCurve;
  final Axis scrollDirection;
  final double deltaThreshold;
  final VoidCallback? onFinalIndex;
  final IndexChangedCallback? onIndexChanged;
  final EdgeInsets padding;
  final bool disableGestures;

  CardView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required Duration animationDuration,
    Curve animationCurve = Curves.linear,
    IndexedWidgetBuilder? secondaryItemBuilder,
    this.controller,
    this.size = _kCardSizeFraction,
    this.itemSpacing = _kItemSpacing,
    BoxBorderBuilder? borderBuilder,
    this.clipBorderRadius = _kClipBorderRadius,
    this.animateToSnapDuration = _kAnimateToSnapDuration,
    this.animateToSnapCurve = _kAnimateToSnapCurve,
    this.scrollDirection = _kScrollDirection,
    this.deltaThreshold = _kDeltaThreshold,
    this.onFinalIndex,
    this.onIndexChanged,
    this.padding = _kPadding,
    this.disableGestures = false,
  })  : borderBuilder = borderBuilder ?? ((_) => null),
        secondaryItemBuilder = secondaryItemBuilder ?? itemBuilder,
        super(
          key: key,
          duration: animationDuration,
          curve: animationCurve,
        );

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      CardViewState();
}

class CardViewState extends AnimatedWidgetBaseState<CardView> {
  ScrollController? _scrollController;
  bool _isAbsorbingPointer = false;
  int _index = 0;
  double _oldOffset = .0;
  double _chipSize = .0;
  bool _shouldUpdateScrollPosition = false;
  bool _didStartDragging = false;

  bool get isVerticalScroll => widget.scrollDirection == Axis.vertical;

  Tween<double>? _size;
  Tween<double>? _itemSpacing;
  Tween<EdgeInsets>? _padding;
  Tween<BorderRadius>? _clipBorderRadius;
  List<IndexedCard> _indexedCards = const <IndexedCard>[];

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

    widget.onIndexChanged?.call(_index);

    super.controller.addListener(() {
      _shouldUpdateScrollPosition = true;
    });
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController?.dispose();

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
    final itemSpacing =
        (_itemSpacing?.evaluate(animation) ?? widget.itemSpacing).clamp(
      .0,
      double.maxFinite,
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: _buildBody(itemSpacing)),
    );
  }

  Widget Function(BuildContext, BoxConstraints) _buildBody(
          double itemSpacing) =>
      (BuildContext context, BoxConstraints constraints) {
        final size = _size?.evaluate(animation) ?? widget.size;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
        final cardSize = size * fullSize;
        final w = isVerticalScroll ? constraints.maxWidth : cardSize;
        final h = isVerticalScroll ? cardSize : constraints.maxHeight;
        final clipBorderRadius =
            (_clipBorderRadius?.evaluate(animation) ?? widget.clipBorderRadius)
                .clamp(
          Radius.zero,
          const Radius.circular(double.maxFinite),
        );

        _scrollController ??= ScrollController(
            keepScrollOffset: false,
            initialScrollOffset: _calculateScrollOffset(constraints, size));

        if (_shouldUpdateScrollPosition) {
          _shouldUpdateScrollPosition = false;

          _scrollController?.jumpTo(_calculateScrollOffset(constraints, size));
        }

        _indexedCards = _buildVisibleCards(
          itemSpacing: itemSpacing,
          clipBorderRadius: clipBorderRadius,
          width: w,
          height: h,
        );

        final fraction = itemSpacing * .5;
        final singleScrollChild = Padding(
          padding: EdgeInsets.only(
            top: isVerticalScroll ? fraction : .0,
            bottom: isVerticalScroll ? fraction : .0,
            left: isVerticalScroll ? .0 : fraction,
            right: isVerticalScroll ? .0 : fraction,
          ),
          child: CardSequence(
            direction:
                isVerticalScroll ? Direction.vertical : Direction.horizontal,
            children: _indexedCards.map((it) => it.widget),
            chipSize: _chipSize,
            cardSize: Size(w, h),
          ),
        );
        final scrollable = ScrollConfiguration(
          behavior: const _NoOverscrollBehavior(),
          child: SingleChildScrollView(
            physics: widget.disableGestures
                ? const NeverScrollableScrollPhysics()
                : null,
            scrollDirection: widget.scrollDirection,
            controller: _scrollController,
            child: singleScrollChild,
          ),
        );

        return AbsorbPointer(
          absorbing: _isAbsorbingPointer,
          child: Listener(
            onPointerDown: _onDragStart,
            onPointerMove: _onDragUpdate,
            onPointerUp: _onDragEnd(constraints),
            child: scrollable,
          ),
        );
      };

  double _calculateScrollOffset(BoxConstraints constraints, double size) {
    final fullSize =
        isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

    _chipSize = ((1.0 - size) * fullSize).clamp(.0, fullSize);

    final jumpToOffset = _index > 0 ? _chipSize : .0;

    return _index.clamp(0, 1) * fullSize - jumpToOffset;
  }

  List<IndexedCard> _buildVisibleCards({
    required double itemSpacing,
    required BorderRadius clipBorderRadius,
    double? width,
    double? height,
  }) =>
      [
        if (_index > 0)
          _buildCard(
            index: _index - 1,
            builder: widget.secondaryItemBuilder,
            itemSpacing: itemSpacing,
            borderBuilder: widget.borderBuilder,
            clipBorderRadius: clipBorderRadius,
            width: width,
            height: height,
          ),
        if (widget.itemCount > 0)
          _buildCard(
            index: _index,
            builder: widget.itemBuilder,
            itemSpacing: itemSpacing,
            borderBuilder: widget.borderBuilder,
            clipBorderRadius: clipBorderRadius,
            width: width,
            height: height,
          ),
        if (_index < widget.itemCount - 1)
          _buildCard(
            index: _index + 1,
            builder: widget.secondaryItemBuilder,
            itemSpacing: itemSpacing,
            borderBuilder: widget.borderBuilder,
            clipBorderRadius: clipBorderRadius,
            width: width,
            height: height,
          ),
      ];

  IndexedCard _buildCard({
    required int index,
    required IndexedWidgetBuilder builder,
    required double itemSpacing,
    required BorderRadius clipBorderRadius,
    required BoxBorderBuilder borderBuilder,
    double? width,
    double? height,
  }) =>
      IndexedCard(
        index: index,
        widget: CardViewChild(
          key: ValueKey(index),
          child: builder(context, index),
          width: width,
          height: height,
          isVerticalScroll: isVerticalScroll,
          border: borderBuilder(index),
          clipBorderRadius: clipBorderRadius,
          itemSpacing: itemSpacing,
          shouldDispose: false,
        ),
      );

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
    _oldOffset = _scrollController!.offset;
  }

  void _onDragUpdate(PointerMoveEvent? event) {
    if (widget.disableGestures) return;

    if (!_didStartDragging) {
      _didStartDragging = true;
      _oldOffset = _scrollController!.offset;
    }
  }

  void Function(PointerUpEvent?) _onDragEnd(BoxConstraints constraints) =>
      (PointerUpEvent? event) async {
        if (widget.disableGestures) return;

        final size = _size?.evaluate(animation) ?? widget.size;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

        _chipSize = (1.0 - size) * fullSize;

        final delta = _scrollController!.offset - _oldOffset;
        int pageOffset = 0;

        if (delta > widget.deltaThreshold && _index < widget.itemCount - 1) {
          pageOffset++;
        } else if (delta < -widget.deltaThreshold && _index > 0) {
          pageOffset--;
        }

        setState(() => _isAbsorbingPointer = true);

        final animationOffset =
            _oldOffset + pageOffset * fullSize - pageOffset * _chipSize;
        final animationFactor =
            (animationOffset - _scrollController!.position.pixels).abs() /
                fullSize;

        await _scrollController!.animateTo(
          animationOffset,
          duration: widget.animateToSnapDuration * animationFactor,
          curve: widget.animateToSnapCurve,
        );

        setState(() {
          _index += pageOffset;
          _isAbsorbingPointer = false;

          widget.controller?.index = _index;

          final jumpToOffset = _index > 0 ? _chipSize : .0;

          _scrollController!
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

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

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
