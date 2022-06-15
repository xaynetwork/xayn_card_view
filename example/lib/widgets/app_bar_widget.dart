import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({
    Key? key,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onFirstPressed,
    required this.onLastPressed,
    required this.counterText,
  }) : super(key: key);
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onFirstPressed;
  final VoidCallback onLastPressed;
  final String counterText;

  @override
  Widget build(BuildContext context) {
    final kittyCounter = Align(
      alignment: Alignment.center,
      widthFactor: 1.7,
      child: Text(
        counterText,
        style: Theme.of(context).textTheme.headline6,
      ),
    );

    final upButton = IconButton(
      onPressed: onUpPressed,
      icon: const FaIcon(FontAwesomeIcons.angleUp),
    );

    final downButton = IconButton(
      onPressed: onDownPressed,
      icon: const FaIcon(FontAwesomeIcons.angleDown),
    );

    final jumpToFirstButton = IconButton(
      onPressed: onFirstPressed,
      icon: const FaIcon(FontAwesomeIcons.anglesUp),
    );

    final jumpToLastButton = IconButton(
      onPressed: onLastPressed,
      icon: const FaIcon(FontAwesomeIcons.anglesDown),
    );

    return AppBar(
      title: const Text('Kitties'),
      centerTitle: false,
      actions: [
        kittyCounter,
        jumpToFirstButton,
        upButton,
        downButton,
        jumpToLastButton,
      ],
    );
  }
}
