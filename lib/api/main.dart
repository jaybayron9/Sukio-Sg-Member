import 'package:flutter/material.dart';

void main() async { 
  runApp(
    MaterialApp(
      home: MyWidget(),
    ),
  );
}

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: (){},
          child: const Text('Trigger Notification'),
        ),
      ),
    );
  }
}
