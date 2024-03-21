import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

import 'package:sukio_member/app.dart';

class LoginOTP extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const LoginOTP({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
  }) : super(key: key);

  @override
  _LoginOTPState createState() => _LoginOTPState();
}

class _LoginOTPState extends State<LoginOTP> {
  bool _isResendAgain = false;
  final bool _isVerified = false;
  final bool _isLoading = false;
  dynamic invalidPassCode = '';
  String _code = '';
  Timer? _timer;
  int _start = 60;
  bool noError = false;

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
    return WillPopScope.new(
      onWillPop: () async {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), //<-- SEE HERE
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // <-- SEE HERE
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
      },
      child: SafeArea(
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
                    child: const FittedBox(fit: BoxFit.contain, child: Icon(Icons.sms)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  const Text(
                    "OTP",
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
                      invalidPassCode ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the OTP?",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      TextButton(
                        onPressed: () {
                          // if (_isResendAgain) return;
                          // resend();
                        },
                        child: Text(
                          _isResendAgain ? "Try again in $_start" : "Request again",
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
                          noError = true; 
                          final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/login"), body: {
                            'phone_number': widget.phoneNumber,
                            'country_code': widget.countryCode,
                            'otp_code': _code,
                          });
                          if (response.statusCode == 200) {
                            final Map<String, dynamic> res = json.decode(response.body);   
                              if (res['status'].toString() == 'false') {
                                setState(() {
                                  invalidPassCode = res['message'];
                                });
                              } else {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                prefs.setString('authId', res['member_id'].toString()); 
                                prefs.setString('membershipId', res['membership_id'].toString()); 
                                prefs.setString('firstName', res['first_name'].toString()); 
                                prefs.setString('lastName', res['last_name'].toString()); 
                                prefs.setString('email', res['email'].toString());
                                prefs.setString('countryCode', res['country_code'].toString());
                                prefs.setString('phoneNumber', res['phone_number'].toString());
                                prefs.setString('role', res['role'].toString());
                                prefs.setString('qr', res['qr'].toString());
                                prefs.setString('group', res['group'].toString());

                                Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) => const App()),
                                );
                              }
                            setState(() {   noError = false; });
                          } else {
                            throw "Request failed with status: ${response.statusCode}";
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
                      text: const TextSpan(children: [
                        TextSpan(
                          text: "Back to Login",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    ); 
  }
}