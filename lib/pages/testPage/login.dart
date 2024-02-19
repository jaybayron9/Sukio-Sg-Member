import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _Login createState() => _Login();
}

class _Login extends State<LoginPage> {
  // CRD session
  Future<void> setSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sessionToken', 'mySesssion');
  }

  Future<String?> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('sessionToken');
  }

  Future<void> deleteSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('sessionToken');
  }

  // CRD cookie
  Future<void> setCookie() async { 
    String cookieJson = jsonEncode({
      'name': "cookieKey", 
      'value': "cookieValue"
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', cookieJson);
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

  Future<void> deleteCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('cookie');
  }

  // CRD local storage
  Future<void> saveTolocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('MyKey', 'MyValue');
  }

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('MyKey');
  }

  Future<void> deleteFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('MyKey');
  }
  
  @override
  void initState() {
    super.initState();

    setCookie();
    printCookie();

    setSession();
    getSession().then((value) {
      print('Session: $value');
    });

    saveTolocalStorage();
    getFromLocalStorage().then((storedValue) {
      if (storedValue != null) {
        print('Value from Local Storage: $storedValue');
      } else {
        print('Value not found in Local Storage.');
      }
    });

    // deleteSession();
    // deleteCookie();
    // deleteFromLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Page'),
      ),
    );
  }
}
