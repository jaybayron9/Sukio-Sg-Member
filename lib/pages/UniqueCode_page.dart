import '/pages/assets.dart';
import 'dart:convert';
import '/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart'; 

class UniqueCode extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const UniqueCode({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
  }) : super(key: key);

  @override
  _UniqueCodeState createState() => _UniqueCodeState();
}

class _UniqueCodeState extends State<UniqueCode> {
  bool _isResendAgain = false;
  bool _isVerified = false;
  bool _isLoading = false;
  dynamic invalidPassCode = '';
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

  void _cookieSession(String cookie) async {
    int position1 = cookie.indexOf("MANOM=");
    int position2 = cookie.indexOf(";", position1);
    session["sessionCookie1"] = sessionCookie1 = cookie.substring(position1 + 6, position2);
    int position3 = cookie.indexOf("MNCOOKIE=");
    int position4 = cookie.indexOf(";", position3);
    session["sessionCookie2"] = sessionCookie2 = cookie.substring(position3 + 9, position4);
    int position5 = cookie.indexOf("MNTOKENS=");
    int position6 = cookie.indexOf(";", position5);
    session["sessionCookie3"] = sessionCookie3 = cookie.substring(position5 + 9, position6);
    storeSession(session); 
  }

  Future<void> sendCode() async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/login"), body: {
      'phone_number': widget.phoneNumber,
      'country_code': widget.countryCode,
      'otp_code': _code,
    });

    if (res.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(res.body);

      if (responseData['status'].toString() == 'false') {
        setState(() {
          invalidPassCode = responseData['message'];
        });
      } else {
        print(responseData);
        _cookieSession(res.headers["set-cookie"].toString());
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              memberId: responseData['member_id'],
              firstName: responseData['first_name'],
              lastName: responseData['last_name'],
              email: responseData['email'],
              countryCode: responseData['country_code'],
              phoneNumber: responseData['phone_number'],
              role: responseData['role'],
              qrCode: responseData['qr'],
            ),
          ),
        );
      }
    } else {
      print("Request failed with status: ${res.statusCode}");
    }
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
                  "Passcode",
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
                      "Don't receive the passcode",
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
                      // onPressed: _code.length < 4 ? null : () => verify(),
                      onPressed: () {
                        // if (_code.length < 4) return;
                        sendCode();
                      },
                      color: Colors.orangeAccent,
                      minWidth: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.05,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: _isLoading
                          ? const SizedBox(
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
                    // if (_verificationError != null)
                    //   Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: Text(
                    //       _verificationError!,
                    //       style: const TextStyle(color: Colors.red),
                    //     ),
                    //   ),
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
