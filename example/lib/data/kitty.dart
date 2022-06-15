import 'package:flutter/foundation.dart';

@immutable
class Kitty {
  final String url;
  final String id;
  final int width;
  final int height;

  Kitty.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        id = json['id'],
        width = json['width'],
        height = json['height'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kitty && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
