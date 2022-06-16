import 'dart:convert';

import 'package:http/http.dart' as http;

import 'kitty.dart';

const kittyApi = 'https://api.thecatapi.com/v1/images/search';

class RemoteDataSource {
  static Future<Kitty> _fetchKitty() async {
    final response = await http.get(Uri.parse(kittyApi));

    if (response.statusCode == 200) {
      final List decodedResponse = jsonDecode(response.body);
      return Kitty.fromJson(decodedResponse.first);
    } else {
      throw Exception('Failed to fetch a kitty :(');
    }
  }

  static Future<List<Kitty>> fetchKittyList(int length) async => Future.wait(
        List.generate(
          length,
          (_) => _fetchKitty(),
          growable: false,
        ),
      );
}
