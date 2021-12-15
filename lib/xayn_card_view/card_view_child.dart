import 'package:flutter/widgets.dart';

class CardViewChild extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final bool isVerticalScroll;
  final BorderRadius clipBorderRadius;
  final double itemSpacing;
  final bool shouldRenderOffstage;
  final bool shouldDispose;

  const CardViewChild({
    Key? key,
    required this.child,
    required this.isVerticalScroll,
    required this.clipBorderRadius,
    required this.itemSpacing,
    required this.shouldRenderOffstage,
    required this.shouldDispose,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CardViewChildState();
}

class _CardViewChildState extends State<CardViewChild>
    with AutomaticKeepAliveClientMixin {
  @override
  void didUpdateWidget(CardViewChild oldWidget) {
    if (oldWidget.shouldDispose != widget.shouldDispose) {
      updateKeepAlive();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final child = constraintToSize();

    if (widget.shouldRenderOffstage) {
      return Offstage(
        child: child,
      );
    }

    return child;
  }

  @override
  bool get wantKeepAlive => !widget.shouldDispose;

  Widget constraintToSize() {
    final padding = EdgeInsets.only(
      bottom: widget.isVerticalScroll ? widget.itemSpacing : .0,
      right: widget.isVerticalScroll ? .0 : widget.itemSpacing,
    ).clamp(
      EdgeInsets.zero,
      const EdgeInsets.all(double.maxFinite),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Padding(
        padding: padding,
        child: ClipRRect(
          child: widget.child,
          borderRadius: widget.clipBorderRadius,
        ),
      ),
    );
  }
}
