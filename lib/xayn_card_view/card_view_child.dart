import 'package:flutter/widgets.dart';

class CardViewChild extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final bool isVerticalScroll;
  final BorderRadius clipBorderRadius;
  final double itemSpacing;
  final bool shouldDispose;

  const CardViewChild({
    Key? key,
    required this.child,
    required this.isVerticalScroll,
    required this.clipBorderRadius,
    required this.itemSpacing,
    required this.shouldDispose,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CardViewChildState();
}

class _CardViewChildState extends State<CardViewChild> {
  @override
  Widget build(BuildContext context) {
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
