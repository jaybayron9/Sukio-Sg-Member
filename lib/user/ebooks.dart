import 'package:flutter/material.dart';

class Ebooks extends StatefulWidget {
  const Ebooks({ Key? key }) : super(key: key);

  @override
  _EbooksState createState() => _EbooksState();
}

class _EbooksState extends State<Ebooks> {
  @override
  Widget build(BuildContext context) {
    return const Center( 
        child: Text('Coming soon...', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 150, 154, 153))) 
    );
  }
}