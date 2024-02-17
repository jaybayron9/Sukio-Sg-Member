import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Map session = {};
String sessionCookie1 = "";
String sessionCookie2 = "";
String sessionCookie3 = "";

Future<bool> storeSession(Map value) async {
  final localStorage = await SharedPreferences.getInstance();
  String encoded = json.encode(value);
  return localStorage.setString('session', encoded);
}
