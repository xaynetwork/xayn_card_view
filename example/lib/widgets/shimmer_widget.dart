import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  const ShimmerWidget({Key? key, this.child}) : super(key: key);
  final Widget? child;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        highlightColor: Colors.grey.shade300,
        baseColor: Colors.grey.shade600,
        child: child ?? const SizedBox.expand(),
      );
}
