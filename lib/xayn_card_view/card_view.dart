import 'package:flutter/widgets.dart';
import 'package:xayn_card_view/xayn_card_view/card_sequence.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_child.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_controller.dart';
import 'package:xayn_card_view/xayn_card_view/card_view_listeners_mixin.dart';
import 'package:xayn_card_view/xayn_card_view/no_overscroll_behavior.dart';

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
typedef CardIdentifierBuilder = String Function(int index);
typedef AuxiliaryCardBuilder = Widget Function(
    BuildContext context, double? width, double? height);

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
  final CardIdentifierBuilder? cardIdentifierBuilder;
  final EdgeInsets padding;
  final bool disableGestures;
  final AuxiliaryCardBuilder? noItemsBuilder;
  final AuxiliaryCardBuilder? finalItemBuilder;

  CardView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required Duration animationDuration,
    this.controller,
    this.size = _kCardSizeFraction,
    this.itemSpacing = _kItemSpacing,
    this.clipBorderRadius = _kClipBorderRadius,
    this.animateToSnapDuration = _kAnimateToSnapDuration,
    this.animateToSnapCurve = _kAnimateToSnapCurve,
    this.scrollDirection = _kScrollDirection,
    this.deltaThreshold = _kDeltaThreshold,
    this.onFinalIndex,
    this.onIndexChanged,
    this.padding = _kPadding,
    this.disableGestures = false,
    this.cardIdentifierBuilder,
    this.noItemsBuilder,
    this.finalItemBuilder,
    Curve animationCurve = Curves.linear,
    IndexedWidgetBuilder? secondaryItemBuilder,
    BoxBorderBuilder? borderBuilder,
  })  : borderBuilder = borderBuilder ?? ((_) => null),
        secondaryItemBuilder = secondaryItemBuilder ?? itemBuilder,
        super(
          key: key,
          duration: animationDuration,
          curve: animationCurve,
        );

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _CardViewState();
}

@protected
abstract class CardViewAnimatedState extends AnimatedWidgetBaseState<CardView> {
  ScrollController? _scrollController;

  @protected
  int index = 0;

  Tween<double>? _size;
  Tween<double>? _itemSpacing;
  Tween<EdgeInsets>? _padding;
  Tween<BorderRadius>? _clipBorderRadius;

  @protected
  int get overflowItemCount =>
      widget.finalItemBuilder != null ? widget.itemCount + 1 : widget.itemCount;

  /// stores the last known box constraints,
  /// only used when triggering jump programmatically via the controller.
  @protected
  BoxConstraints? get lastKnownConstraints;

  @protected
  ScrollController? get scrollController => _scrollController;

  @protected
  double get currentSize => _size?.evaluate(animation) ?? widget.size;

  @protected
  double get itemSpacing =>
      _itemSpacing?.evaluate(animation) ?? widget.itemSpacing;

  @protected
  EdgeInsets get padding => _padding?.evaluate(animation) ?? widget.padding;

  @protected
  BorderRadius get clipBorderRadius =>
      _clipBorderRadius?.evaluate(animation) ?? widget.clipBorderRadius;

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
}

class _CardViewState extends CardViewAnimatedState with CardViewListenersMixin {
  List<Widget> _indexedCards = const <Widget>[];
  BoxConstraints? _lastKnownConstraints;

  @override
  BoxConstraints? get lastKnownConstraints => _lastKnownConstraints;

  @override
  void initState() {
    super.initState();

    final controller = widget.controller;

    if (controller != null) {
      assert(controller.index == 0 || controller.index < widget.itemCount,
          'Controller index is out of bound. index should be less than itemCount.');
      _updateIndex(controller.index);

      controller.addListener(_onControllerChanged);
    }

    widget.onIndexChanged?.call(index);

    if (widget.itemCount == 1) widget.onFinalIndex?.call();

    super.controller.addListener(_updateScrollPosition);
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController?.dispose();

    super.controller.removeListener(_updateScrollPosition);
    widget.controller?.removeListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itemCount != widget.itemCount) {
      _updateIndex(
          widget.itemCount > 0 ? index.clamp(0, widget.itemCount - 1) : 0);

      widget.controller?.index = index;

      if (widget.itemCount == 1) widget.onFinalIndex?.call();
    }

    if (oldWidget.scrollDirection != widget.scrollDirection ||
        oldWidget.size != widget.size) {
      _updateScrollPosition();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding.clamp(
          EdgeInsets.zero,
          const EdgeInsets.all(double.maxFinite),
        ),
        child: LayoutBuilder(
          builder: _buildBody(
            itemSpacing.clamp(
              .0,
              double.maxFinite,
            ),
          ),
        ),
      );

  Widget Function(BuildContext, BoxConstraints) _buildBody(
          double itemSpacing) =>
      (BuildContext context, BoxConstraints constraints) {
        final size = currentSize;
        final fullSize =
            isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;
        final cardSize = size * fullSize;
        final w = isVerticalScroll ? constraints.maxWidth : cardSize;
        final h = isVerticalScroll ? cardSize : constraints.maxHeight;

        _lastKnownConstraints = constraints;

        final scrollController = _scrollController ??= ScrollController(
            keepScrollOffset: false,
            initialScrollOffset: _calculateScrollOffset(constraints, size));

        _indexedCards = _buildVisibleCards(
          context: context,
          itemSpacing: itemSpacing,
          clipBorderRadius: clipBorderRadius.clamp(
            Radius.zero,
            const Radius.circular(double.maxFinite),
          ),
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
            children: _indexedCards,
            chipSize: chipSize,
            cardSize: Size(w, h),
          ),
        );
        final scrollable = ScrollConfiguration(
          behavior: const NoOverscrollBehavior(),
          child: SingleChildScrollView(
            physics: widget.disableGestures
                ? const NeverScrollableScrollPhysics()
                : null,
            scrollDirection: widget.scrollDirection,
            controller: scrollController,
            child: singleScrollChild,
          ),
        );

        return Listener(
          onPointerDown:
              widget.disableGestures ? null : onDragStart(constraints),
          onPointerMove:
              widget.disableGestures ? null : onDragUpdate(constraints),
          onPointerUp: widget.disableGestures ? null : onDragEnd(constraints),
          child: scrollable,
        );
      };

  void _updateScrollPosition() {
    final constraints = lastKnownConstraints;
    final scrollController = _scrollController;

    if (constraints == null || scrollController == null) return;

    final jumpTarget = _calculateScrollOffset(constraints, currentSize);

    if (!isScrollPosAnimating &&
        !isDragActive &&
        scrollController.offset != jumpTarget) {
      scrollController.jumpTo(jumpTarget);
    }
  }

  double _calculateScrollOffset(BoxConstraints constraints, double size) {
    final fullSize =
        isVerticalScroll ? constraints.maxHeight : constraints.maxWidth;

    chipSize = ((1.0 - size) * fullSize).clamp(.0, fullSize);

    final jumpToOffset = index > 0 ? chipSize : .0;

    return index.clamp(0, 1) * fullSize - jumpToOffset;
  }

  List<Widget> _buildVisibleCards({
    required double itemSpacing,
    required BorderRadius clipBorderRadius,
    required BuildContext context,
    double? width,
    double? height,
  }) {
    // resolvedIndex is the actual data index, without a maybe-included finalItemBuilder card
    final resolvedIndex = index > 0 ? index.clamp(0, widget.itemCount - 1) : 0;
    final noItemsBuilder = widget.noItemsBuilder;
    final finalItemBuilder = widget.finalItemBuilder;

    if (widget.itemCount == 0 && noItemsBuilder != null) {
      return [noItemsBuilder(context, width, height)];
    }

    final widgets = [
      if (resolvedIndex > 0 && index <= widget.itemCount - 1)
        _buildCard(
          index: resolvedIndex - 1,
          builder: widget.secondaryItemBuilder,
          itemSpacing: itemSpacing,
          borderBuilder: widget.borderBuilder,
          clipBorderRadius: clipBorderRadius,
          width: width,
          height: height,
        ),
      if (widget.itemCount > 0)
        _buildCard(
          index: resolvedIndex,
          builder: widget.itemBuilder,
          itemSpacing: itemSpacing,
          borderBuilder: widget.borderBuilder,
          clipBorderRadius: clipBorderRadius,
          width: width,
          height: height,
        ),
      if (resolvedIndex < widget.itemCount - 1)
        _buildCard(
          index: resolvedIndex + 1,
          builder: widget.secondaryItemBuilder,
          itemSpacing: itemSpacing,
          borderBuilder: widget.borderBuilder,
          clipBorderRadius: clipBorderRadius,
          width: width,
          height: height,
        ),
      if (index >= widget.itemCount - 1 && finalItemBuilder != null)
        finalItemBuilder(context, width, height),
    ];

    return widgets;
  }

  Widget _buildCard({
    required int index,
    required IndexedWidgetBuilder builder,
    required double itemSpacing,
    required BorderRadius clipBorderRadius,
    required BoxBorderBuilder borderBuilder,
    double? width,
    double? height,
  }) {
    final cardIdentifierBuilder = widget.cardIdentifierBuilder;
    final key = cardIdentifierBuilder != null
        ? Key(cardIdentifierBuilder(index))
        : ValueKey(index);

    return CardViewChild(
      key: key,
      child: builder(context, index),
      width: width,
      height: height,
      isVerticalScroll: isVerticalScroll,
      border: borderBuilder(index),
      clipBorderRadius: clipBorderRadius,
      itemSpacing: itemSpacing,
      shouldDispose: false,
    );
  }

  void _onControllerChanged() {
    final controller = widget.controller!;
    final offset = controller.getNextOffsetAndReset();

    if (offset != 0) {
      jump(pageOffset: offset);
    } else if (index != controller.index) {
      setState(() {
        if (controller.index == index) return;

        index = controller.index;

        widget.onIndexChanged?.call(index);

        _updateScrollPosition();
      });
    }
  }

  void _updateIndex(int nextIndex) {
    if (nextIndex == index) return;

    index = nextIndex;

    if (widget.itemCount > 0 && nextIndex == widget.itemCount - 1) {
      widget.onFinalIndex?.call();
    }

    if (index == 0 && _scrollController?.hasClients == true) {
      _scrollController!.jumpTo(.0);
    }
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
