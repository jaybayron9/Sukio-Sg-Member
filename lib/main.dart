import 'package:development/pages/Approval_page.dart';
import 'package:development/pages/dashboard_page.dart';
import 'package:development/pages/login_page.dart';
import 'package:development/pages/qr_code_page.dart';
import 'package:development/pages/register_page.dart';
import 'package:development/pages/splash_page.dart';
import 'package:development/pages/validation_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 

void main() { 
  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}