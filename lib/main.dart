// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';  
import 'package:flutter/services.dart';
import 'auth/login.dart';

void main() async { 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
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
  const Main({ Key? key }) : super(key: key);

  @override 
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return const Login();
  }
}