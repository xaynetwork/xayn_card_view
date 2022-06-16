import 'package:flutter/material.dart';

import '../data/kitty.dart';
import 'shimmer_widget.dart';

class KittyCard extends StatelessWidget {
  final Kitty kitty;

  const KittyCard({Key? key, required this.kitty}) : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          kitty.url,
          fit: BoxFit.cover,
          height: 400,
          loadingBuilder: (_, image, progress) =>
              progress == null ? image : const ShimmerWidget(),
        ),
      );
}
