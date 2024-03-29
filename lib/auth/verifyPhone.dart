import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sukio_member/auth/login.dart';
import 'package:sukio_member/auth/uploadProfilePict.dart';
import 'package:sukio_member/utils/registerUser.dart';

class VerifyPhone extends StatefulWidget {  
  const VerifyPhone({
    Key? key
  }) : super(key: key);

  @override
  _VerifyPhoneState createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends State<VerifyPhone> {
  Map<String, String?> user = {};
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

  @override
  void initState() {
    super.initState(); 
    registeredData();
  }

  registeredData() async {
    Map<String, String?> userData = await RegisterUserData.getUser(); 
    setState(() {
      user =  userData;
    }); 
  }

  Future<bool> resendOTP() async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/sendOTP"), body: {
      'phone_number': user['phoneNumber'],
      'country_code': user['countryCode'],
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
                  '',
                  // 'Please enter the 4-digit code sent to \n +${widget.countryCode}${widget.phoneNumber}',
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
                      "Didn't receive the OTP?",
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
                        final response = await http.post(
                          Uri.parse("https://ww2.selfiesmile.app/member/verify/phone"),
                          body: { 
                            'first_name': user['firstName'],
                            'last_name': user['lastName'],
                            'email': user['email'],
                            'country_code': user['countryCode'],
                            'phone_number': user['phoneNumber'],
                            'phone_code': _code,
                          }
                        );

                        if (response.statusCode == 200) {
                          final Map<String, dynamic> res = json.decode(response.body); 
                          if (res['status'].toString() == 'true') {
                            await RegisterUserData().setRegisterId(res['request_id']); 
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (BuildContext context) => const UploadProfilePict(),
                            //     fullscreenDialog: true,
                            //   ),
                            // );

                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.success,
                              animType: AnimType.rightSlide,
                              dismissOnTouchOutside: false,
                              title: 'Successfully Registered',
                              desc: res['message'], 
                              btnOkOnPress: () async { 
                                OneSignal.Debug.setLogLevel(OSLogLevel.verbose); 
                                OneSignal.Debug.setAlertLevel(OSLogLevel.none);
                                OneSignal.consentRequired(false); 
                                OneSignal.initialize('df33667d-80b5-4062-9ccb-2325537fa02e');  
                                OneSignal.Notifications.clearAll(); 
                                OneSignal.User.pushSubscription.addObserver((state) async { 
                                  await http.post(Uri.parse('https://ww2.selfiesmile.app/member/notify/approval'), body: { 
                                    'country_code': user['countryCode'],
                                    'phone_number': user['phoneNumber'],
                                    'subscription_id': OneSignal.User.pushSubscription.id.toString()
                                  });
                                });
                                OneSignal.Notifications.addPermissionObserver((state) async { 
                                  await http.post(Uri.parse('https://ww2.selfiesmile.app/member/notify/approval'), body: { 
                                    'country_code': user['countryCode'],
                                    'phone_number': user['phoneNumber'],
                                    'subscription_id': OneSignal.User.pushSubscription.id.toString()
                                  }); 
                                }); 
                                await OneSignal.Notifications.requestPermission(true); 

                                Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => const Login()),
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