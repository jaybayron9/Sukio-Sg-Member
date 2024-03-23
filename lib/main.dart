// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sukio_member/auth/enrollFace.dart';
import 'package:sukio_member/auth/uploadProfilePict.dart';
import 'package:sukio_member/utils/user.dart';
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
    final response = await http.post(
      Uri.parse("https://ww2.selfiesmile.app/members/auth"),
      body: {'member_id': memberId},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> res = json.decode(response.body);

      if (res['status'].toString() == 'true') {
        SetUser user = SetUser(
          res['member_id'],
          res['membership_id'],
          res['first_name'],
          res['last_name'],
          res['email'],
          res['country_code'],
          res['phone_number'],
          res['role'],
          res['qr'],
          res['group'],
          res['profile_picture'],
        );
        await user.setUser();

        return true;
      } else {
        RemoveUser user = RemoveUser();
        user.removeUser();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const App() : const Login();
    // return const UploadProfilePict();
    // return const EnrollFace();
  }
} 