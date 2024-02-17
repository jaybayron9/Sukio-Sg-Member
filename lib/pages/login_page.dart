// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously
import '/pages/assets.dart';
import '/pages/UniqueCode_page.dart';
import '/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneNumberController = TextEditingController();

  String? scannedQRData;

  Future<void> _showScanResultDialog(String qrdata) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Result'),
          content: RichText(
            text: TextSpan(
              text: 'Scanned QR Code: ',
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: qrdata,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _launchURL(qrdata);
                    },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  Future<void> _qrScanner() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      try {
        String? qrdata = await scanner.scan();
        if (qrdata != null) {
          setState(() {
            scannedQRData = qrdata; // Update the scannedQRData variable
          });
          print("Scanned QR Code: $qrdata");
          // Show the dialog with the scanned result
          await _showScanResultDialog(qrdata);
        } else {
          print("User canceled the scan.");
        }
      } catch (e) {
        print("Error scanning QR code: $e");
        // Handle the error accordingly
      }
    } else {
      var isGrant = await Permission.camera.request();
      if (isGrant.isGranted) {
        try {
          String? qrdata = await scanner.scan();
          if (qrdata != null) {
            setState(() {
              scannedQRData = qrdata; // Update the scannedQRData variable
            });
            print("Scanned QR Code: $qrdata");
            // Show the dialog with the scanned result
            await _showScanResultDialog(qrdata);
          } else {
            print("User canceled the scan.");
          }
        } catch (e) {
          print("Error scanning QR code: $e");
          // Handle the error accordingly
        }
      }
    }
  }

  Country country = CountryParser.parseCountryCode('SG');
  String countryCode = '';

  String emptyPhonErr = '';
  String invPhoneErr = '';
  String phoneNotFoundErr = '';
  String notApprove = '';

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

  Future<void> sendData() async {
    try {
      final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/login"), body: {
        'phone_number': phoneNumberController.text,
        'country_code': countryCode,
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(res.body);
        print(responseData);

        if (responseData['status'].toString() == 'false') {
          print(responseData);
          setState(() {
            emptyPhonErr = responseData['empty_phone'];
            notApprove = responseData['not_approved'];

            if (responseData['empty_phone'] == '') {
              phoneNotFoundErr = responseData['not_found'];
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UniqueCode(
                phoneNumber: phoneNumberController.text,
                countryCode: countryCode,
              ),
            ),
          );
          _cookieSession(res.headers["set-cookie"].toString()); 
        }
      } else {
        print("Request failed with status: ${res.statusCode}");
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void showPicker() {
    showCountryPicker(
      context: context,
      countryListTheme: const CountryListThemeData(
        bottomSheetHeight: 600,
      ),
      onSelect: (country) {
        setState(() {
          this.country = country;
        });
      },
    );
  }

  showError(value1, value2, value3) {
    if (value1 != '') {
      return Container(
        margin: const EdgeInsets.only(left: 25, bottom: 20),
        child: Text(
          value1,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (value2 != '') {
      return Container(
        margin: const EdgeInsets.only(left: 25, bottom: 20),
        child: Text(
          value2,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (value3 != '') {
      return Container(
        margin: const EdgeInsets.only(left: 25, bottom: 20),
        child: Text(
          value3,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Stack(
                  children: [
                    Container(
                      // margin: const EdgeInsets.only(bottom: 5),
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orangeAccent, Colors.orangeAccent],
                          end: Alignment.bottomCenter,
                          begin: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100)),
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: 2, // Adjust the scale factor as needed
                          child: const Image(
                            image: AssetImage('images/splashLogo.png'),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        onPressed: _qrScanner,
                        icon: Icon(Icons.qr_code_scanner),
                        iconSize: 30,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 25, right: 25), // Align the text to the right within its container
                  child: const Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 20, right: 20), // Align the text to the right within its container
                  child: const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 25, right: 25), // Align the text to the right within its container
                  child: Text(
                    'Check-in,',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 25, right: 25), // Align the text to the right within its container
                  child: Text(
                    'Enter your register phone number to access your account.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  margin: const EdgeInsets.only(left: 25, right: 25),
                  child: Column(
                    children: <Widget>[
                      Container(margin: const EdgeInsets.only(bottom: 10)),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey, width: 1.0), // Add a border
                        ),
                        child: TextFormField(
                          controller: phoneNumberController,
                          onFieldSubmitted: (phoneNumber) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('+${country.phoneCode}$phoneNumber'),
                              ),
                            );
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Phone number",
                            prefixIcon: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: showPicker,
                              child: Container(
                                height: 55,
                                width: 90,
                                alignment: Alignment.center,
                                child: Text(
                                  '${country!.flagEmoji} +${country!.phoneCode}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [showError(emptyPhonErr, phoneNotFoundErr, notApprove)],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            countryCode = country!.phoneCode;
                            sendData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: "Not yet a Member? ",
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextSpan(
                                  text: "Register",
                                  style: TextStyle(color: Colors.orangeAccent),
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
            ),
          ),
        ),
      ),
    );
  }
}
