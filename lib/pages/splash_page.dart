import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '/pages/register_page.dart';
import '/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import '/pages/dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> { 
  @override
  void initState() {
    super.initState();  

    Timer(const Duration(milliseconds: 4000), () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [whiteColors, lightColors], end: Alignment.bottomCenter, begin: Alignment.topCenter),
      ),
      child: const Center(
        child: Image(
          image: AssetImage('images/splashLogo.png'),
          width: 300, // specify your desired width
          height: 300, // specify your desired height
        ),
      ),
    ));
  }
}
