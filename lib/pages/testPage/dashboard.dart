import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  const DashboardPage({ Key? key, }) : super(key: key);

  @override
    _Dashboard createState() => _Dashboard(); 
}

class _Dashboard extends State<DashboardPage> { 
  Future<String?> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('sessionToken');
  } 

  Future<void> printCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cookieJson = prefs.getString('cookie');

    if (cookieJson != null) {
      Map<String, dynamic> cookieMap = jsonDecode(cookieJson);
      String cookieName = cookieMap['name'];
      String cookieValue = cookieMap['value'];

      print('Cookie Name: $cookieName');
      print('Cookie Value: $cookieValue');
    } else {
      print('Cookie not found.');
    }
  }

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('MyKey');
  }

  @override
  void initState() {
    super.initState();

    Future<void> printCookie() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cookieJson = prefs.getString('cookie');

      if (cookieJson != null) {
        Map<String, dynamic> cookieMap = jsonDecode(cookieJson);
        String cookieName = cookieMap['name'];
        String cookieValue = cookieMap['value'];

        print('Cookie Name: $cookieName');
        print('Cookie Value: $cookieValue');
      } else {
        print('Cookie not found.');
      }
    }

    getSession().then((value) {
      print('Session: $value');
    });

    getFromLocalStorage().then((storedValue) {
      if (storedValue != null) {
        print('Value from Local Storage: $storedValue');
      } else {
        print('Value not found in Local Storage.');
      }
    });

    getFromLocalStorage().then((storedValue) {
      if (storedValue != null) {
        print('Value from Local Storage: $storedValue');
      } else {
        print('Value not found in Local Storage.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Dashboard'),
      ),
    );
  }
}