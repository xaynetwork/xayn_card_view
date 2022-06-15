import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitty_app/widgets/app_bar_widget.dart';
import 'package:xayn_card_view/xayn_card_view.dart';

import 'data/kitty.dart';
import 'data/remote_data_source.dart';
import 'widgets/final_card.dart';
import 'widgets/kitty_card.dart';
import 'widgets/loading_widget.dart';
import 'widgets/shimmer_widget.dart';

const maxListLength = 8;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final Future<List<Kitty>> _kitties =
      RemoteDataSource.fetchKittyList(maxListLength);
  final CardViewController controller = CardViewController();
  int currentIndex = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarWidget = AppBarWidget(
      counterText: '${(currentIndex + 1).toString()}/$maxListLength',
      onDownPressed: () {
        if (currentIndex < maxListLength) {
          controller.jump(JumpDirection.down);
        }
      },
      onUpPressed: () {
        if (currentIndex > 0) {
          controller.jump(JumpDirection.up);
        }
      },
      onFirstPressed: () => controller.index = 0,
      onLastPressed: () => controller.index = maxListLength - 1,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 50.0),
        child: appBarWidget,
      ),
      body: _buildKittyList(),
    );
  }

  _buildKittyList() => LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<List<Kitty>>(
          future: _kitties,
          builder: (context, snapshot) {
            final horizontalMargin = constraints.maxWidth * 0.1;
            final kittyList = snapshot.data ?? [];
            return _buildCardView(kittyList, horizontalMargin);
          },
        ),
      );

  _buildCardView(List<Kitty> kitties, double horizontalPadding) => CardView(
        controller: controller,
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        animationDuration: const Duration(seconds: 1),
        deltaThreshold: 15,
        itemCount: kitties.length,
        itemSpacing: 20,
        itemBuilder: (_, int index) => KittyCard(kitty: kitties[index]),
        disableGestures: false,
        secondaryItemBuilder: (_, int index) => ShimmerWidget(
          child: KittyCard(kitty: kitties[index]),
        ),
        onIndexChanged: _onIndexChanged,
        onFinalIndex: _showFinalCardSnackBar,
        finalItemBuilder: (_, width, height) => FinalCard(
          height: height == null ? null : height / 5,
        ),
        noItemsBuilder: (_, __, ___) => const LoadingWidget(),
      );

  _showFinalCardSnackBar() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "End of kitty photos :(",
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 1),
        ),
      );

  _onIndexChanged(int index) {
    if (currentIndex != index) {
      setState(() => currentIndex = index);
    }
  }
}
