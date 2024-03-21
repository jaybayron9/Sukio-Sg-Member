// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  

import 'auth/login.dart';
import 'app.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Sukyo Member',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final storedValue = await getFromLocalStorage();
    if (storedValue != null) {
      final isAuthenticated = await auth(storedValue.toString());
      setState(() {
        _isLoggedIn = isAuthenticated;
      });
    }
  }

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authId');
  }

  Future<bool> auth(memberId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse("https://ww2.selfiesmile.app/members/auth"),
      body: {'member_id': memberId},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> res = json.decode(response.body);

      if (res['status'].toString() == 'true') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('authId', res['member_id'].toString()); 
        prefs.setString('membershipId', res['membership_id'].toString()); 
        prefs.setString('firstName', res['first_name'].toString()); 
        prefs.setString('lastName', res['last_name'].toString()); 
        prefs.setString('email', res['email'].toString());
        prefs.setString('countryCode', res['country_code'].toString());
        prefs.setString('phoneNumber', res['phone_number'].toString());
        prefs.setString('role', res['role'].toString());
        prefs.setString('qr', res['qr'].toString());
        prefs.setString('group', res['group'].toString());

        return true;
      } else {
        prefs.remove('authId');
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const App() : const Login();
  }
}
