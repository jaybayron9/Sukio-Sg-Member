// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sukio_member/auth/login.dart';
import 'package:sukio_member/auth/registerFace.dart';
import 'package:sukio_member/utils/registerUser.dart';  
import 'package:url_launcher/url_launcher.dart';

class EnrollFace extends StatefulWidget {
  const EnrollFace({ Key? key }) : super(key: key);

  @override
  _FaceRecogState createState() => _FaceRecogState();
}

class _FaceRecogState extends State<EnrollFace> {  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.blue.shade900, 
      ),
      backgroundColor: Colors.blue.shade900,
      body: Column( 
        children: [
          const Text('Enroll face', style: TextStyle(fontSize: 35, color: Colors.white)), 
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: const Text(
              'For best results, hold the device 20 cm to 50 cm from your face in an environment that is neither too bright nor too dim.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 50),  
          const Icon(Icons.mood, color: Colors.white, size: 300, weight: 10, ),
          const SizedBox(height: 30),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            child: Text.rich(
              TextSpan(
                text: 'By tapping "Continue" you indicate that you have read and agree to the ',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Statement on Using Face Recognition',
                    style: const TextStyle( 
                      color: Colors.blue, 
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      launchUrl(Uri.parse('https://www.itfs.org.sg')); 
                    },
                  ), 
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox( 
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async { 
                        await RegisterUserData().deleteRegisterData(); 
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Cancel",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                          const Visibility(
                            visible: false,
                            child: Row(
                              children: [
                                SizedBox(width: 10),
                                SizedBox( 
                                  height: 17,
                                  width: 17,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70)
                                  ),
                                )
                              ],
                            ),
                          ), 
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded( 
                  child: SizedBox( 
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async { 
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const RegisterFace()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continue",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                          const Visibility(
                            visible: false,
                            child: Row(
                              children: [
                                SizedBox(width: 10),
                                SizedBox( 
                                  height: 17,
                                  width: 17,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70)
                                  ),
                                )
                              ],
                            ),
                          ), 
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ), 
        ],
      )
    );
  }
}