import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<Map> loadSession(String name) async {
  final localStorage = await SharedPreferences.getInstance();
  String? encodedMap = localStorage.getString(name);
  if (encodedMap != null) {
    return json.decode(encodedMap);
  } else {
    return {};
  }
}