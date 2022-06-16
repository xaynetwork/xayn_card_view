import 'package:flutter/material.dart';

class FinalCard extends StatelessWidget {
  const FinalCard({Key? key, required this.height}) : super(key: key);
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        child: const Center(
          child: Text('Nothing more to show!'),
        ),
      );
}
