// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:development/pages/Approval_page.dart';
import 'package:development/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class Verification extends StatefulWidget {
  final String first_name;
  final String last_name;
  final String phone_number;
  final String email;
  final String country_code;

  const Verification({
    Key? key,
    required this.first_name,
    required this.last_name,
    required this.phone_number,
    required this.email,
    required this.country_code,
  }) : super(key: key);

  @override
  _VerificationState createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  bool _isResendAgain = false;
  bool _isVerified = false;
  bool _isLoading = false;
  String _code = '';
  late Timer _timer;
  int _start = 60;

  void resend() {
    setState(() {
      _isResendAgain = true;
    });

    resendOTP();

    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      setState(() {
        if (_start == 0) {
          _start = 5;
          _isResendAgain = false;
          timer.cancel();
        } else {
          _start--;
        }
      });
    });
  }

  String msgSuccess = '';
  bool isResendSuccess = false;

  Future<bool> resendOTP() async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/sendOTP"),
      body: {  
        'phone_number': widget.phone_number,
        'country_code': widget.country_code,
      }
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(res.body);

      if (responseData['status'].toString() == 'true') {
        setState(() {
          msgSuccess = responseData['message'];
        });
        return isResendSuccess = true;
      }
    }

    return isResendSuccess = false;
  }

  // Future<void> sendData() async { 
  //     final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/verifyPhone"), 
  //     body: {
  //       'first_name': widget.first_name,
  //       'last_name': widget.last_name,
  //       'email': widget.email,
  //       'country_code': widget.country_code,
  //       'phone_number': widget.phone_number,
  //       'otp_code': _code,
  //     });

  //     if (res.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(res.body);
  //       print(responseData);
  //       return responseData['status']; 
  //     }  
  // }

  Future<void> verifyPhone() async { 
    try {
        final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/verifyPhone"), body: {
          'first_name': widget.first_name,
          'last_name': widget.last_name,
          'email': widget.email,
          'country_code': widget.country_code,
          'phone_number': widget.phone_number,
          'phone_code': _code,
        });

        if (res.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(res.body);

          print(responseData);

          if (responseData['status'].toString() == 'true' ) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Success"),
                  content: Text(responseData['message'].toString()),
                );
              },
            );

            Future.delayed(const Duration(seconds: 8), () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            });
          }
        } 
    } catch (e) {
      print("Error: $e");
    }
  }

  String? _verificationError;

  // verify() async {
    // setState(() {
    //   _isLoading = true;
    //   _verificationError = null;
    // });
    // sendData();
    // const oneSec = Duration(milliseconds: 500);

    // _timer = Timer.periodic(oneSec, (timer) async {
      // try {
        // List resposeData = sendData(_code, widget.country_code, widget.phone_number,widget.first_name, widget.last_name, widget.email);

        // print(resposeData);

        // setState(() {
        //   _isLoading = false;
        //   _isVerified = resposeData.toString() == 'true' ? true : false;
        // });

    //     if (_isVerified) {
    //         Navigator.pushReplacement(
    //         context,
    //         MaterialPageRoute(builder: (context) => const ApprovalPage()),
    //       );
    //       timer.cancel(); // Cancel the timer as verification is successful
    //     } else {

    //       // Delayed execution to clear the error message after 3 seconds
    //       Future.delayed(Duration(seconds: 2), () {
    //         setState(() {
    //           _verificationError = null;
    //         });
    //       });
    //     }
    //   } catch (e) {
    //     setState(() {
    //       _isLoading = false;
    //       _isVerified = false; // Set to false if verification fails
    //       _verificationError = "Error occurred during verification"; // Set the error message
    //     });
    //   }
    // });
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: MediaQuery.of(context).size.height * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30,),
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Transform.rotate(
                      angle: 38,
                      child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            child: Lottie.network(
                              'https://lottie.host/4f09a893-a40c-4f46-bc25-15c3e7f71d55/Lhr2Wq0MGX.json',
                            ),
                          ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Text(
                  "Verification",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  'Please enter the 4-digit code sent to \n +${widget.country_code}${widget.phone_number}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                VerificationCode(
                  length: 4,
                  textStyle: const TextStyle(fontSize: 20),
                  underlineColor: Colors.blueAccent,
                  keyboardType: TextInputType.number,
                  onCompleted: (value) {
                    setState(() {
                      _code = value;
                    });
                  },
                  onEditing: (value) {},
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't receive the OTP",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_isResendAgain) return;
                        resend();
                      },
                      child: Text(
                        _isResendAgain ? "Try again in $_start" : "Resend",
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    )
                  ],
                ),
                Visibility(
                  visible: isResendSuccess,
                  child: Text(
                    msgSuccess,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Column(
                  children: [
                    MaterialButton(
                      disabledColor: Colors.grey.shade300,
                      onPressed: () {
                        verifyPhone();
                      }, 
                      color: Colors.orangeAccent,
                      minWidth: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.05,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: _isLoading
                          ? const  SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.blueAccent,
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : _isVerified
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : const Text(
                                  "Verify",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                    ),
                    // Display the error message in red
                    if (_verificationError != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _verificationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: "Back to Home",
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
