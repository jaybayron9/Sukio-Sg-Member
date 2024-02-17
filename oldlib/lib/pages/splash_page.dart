import 'dart:async';

import '../../oldlib/lib/pages/register_page.dart';
import '../../oldlib/lib/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  Future<void> auth() async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/auth"), headers: {});
    if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(res.body);

        print(responseData);
    }
  }


  @override
  void initState() {

    super.initState();
    Timer(const Duration(milliseconds: 4000), () {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [whiteColors, lightColors],
            end: Alignment.bottomCenter,
            begin: Alignment.topCenter
          ),
        ),
      child: const Center(
        child: Image(
          image: AssetImage('images/splashLogo.png'),
          width: 700, // specify your desired width
          height: 700, // specify your desired height
        ),
      ),
      )
    );
  }
}
