import 'dart:async';
import 'loginPage.dart';
import '/utils/color.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2000), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
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
            width: 300,
            height: 300,
          ),
        ),
      ),
    );
  }
}
