import 'dart:convert';
import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart'; 
import '/pages/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_verification_code/flutter_verification_code.dart';

class Verification extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String countryCode;

  const Verification({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.countryCode,
  }) : super(key: key);

  @override
  VerificationState createState() => VerificationState();
}

class VerificationState extends State<Verification> {
  late Timer _timer;
  final bool _isVerified = false;
  final bool _isLoading = false;
  bool _isResendAgain = false;
  bool isResendSuccess = false;
  bool noError = false; 
  String _code = '';
  String? _verificationError;  
  String msgSuccess = '';
  dynamic invalidCode = ''; 
  int _start = 60; 

  Future<bool> resendOTP() async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/sendOTP"), body: {
      'phone_number': widget.phoneNumber,
      'country_code': widget.countryCode,
    });

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
                const SizedBox(
                  height: 30,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: const FittedBox(fit: BoxFit.contain, child: Icon(Icons.sms_rounded)),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Text(
                  "Verification",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  'Please enter the 4-digit code sent to \n +${widget.countryCode}${widget.phoneNumber}',
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
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Text(
                    invalidCode ?? '',
                    style: const TextStyle(color: Colors.red),
                  ),
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
                      onPressed: () async {
                        setState(() { noError = true; });
                        try {
                          final response = await http.post(
                            Uri.parse("https://ww2.selfiesmile.app/members/verifyPhone"),
                            body: {
                              'first_name': widget.firstName,
                              'last_name': widget.lastName,
                              'email': widget.email,
                              'country_code': widget.countryCode,
                              'phone_number': widget.phoneNumber,
                              'phone_code': _code,
                            }
                          );

                          if (response.statusCode == 200) {
                            final Map<String, dynamic> res = json.decode(response.body);
                            print(res);
                            if (res['status'].toString() == 'true') { 
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.success,
                                animType: AnimType.rightSlide,
                                dismissOnTouchOutside: false,
                                title: 'Successfully Registered',
                                desc: res['message'], 
                                btnOkOnPress: () { 
                                  Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                              ).show();   
                            } else {
                              setState(() {
                                invalidCode = res['invalid_code'].toString();
                              }); 
                            }
                            setState(() { noError = false; });
                          }
                        } catch (e) {
                          debugPrint("Error: $e");
                        }
                      },
                      color: Colors.amber.shade500,
                      minWidth: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.05,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Verify",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Visibility(
                            visible: noError,
                            child: const Row(
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
                      )
                    ),  
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: "Back to Register",
                        style: TextStyle(color: Colors.blue.shade900),
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
