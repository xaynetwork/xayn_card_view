import 'package:flutter/material.dart';
import 'package:xayn_card_view/xayn_card_view/card_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const data = [1, 2, 3, 4, 5, 6];

    return MaterialApp(
      title: 'Swipe my Doggo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.red,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.black12.withOpacity(0.6),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            elevation: 0.5,
          )),
      home: SafeArea(
          child: Container(
        color: Colors.white,
        child: CardView(
          itemSpacing: 24,
          itemCount: data.length,
          itemBuilder: (context, index) => Container(
            color: Colors.red,
            width: double.maxFinite,
            child: Text('$index'),
          ),
        ),
      )),
    );
  }
}
