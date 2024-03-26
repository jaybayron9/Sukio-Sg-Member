// ignore_for_file: avoid_print

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'package:sukio_member/auth/loginOTP.dart';
import 'package:sukio_member/auth/register.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth/error_codes.dart' as auth_error;



class Login extends StatefulWidget {
  const Login({ Key? key }) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
} 


class _LoginState extends State<Login> {
  final LocalAuthentication _biometricAuth = LocalAuthentication();
  final GlobalKey<FormState> loginForm = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  Country country = CountryParser.parseCountryCode('SG');
  String emptyPhonErr = '';
  String phoneNotFoundErr = '';
  String notApprove = '';
  bool noError = false;

  @override
  void initState() {
    super.initState();  
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Exit App"),
              content: const Text("Do you want to exit the app?"),
              actions: [
                TextButton(
                  child: const Text("No"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text("Yes"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                  },
                ),
              ],
            );
          },
        ); 
        return false;
      }, 
      child: Scaffold(
        backgroundColor: Colors.blue.shade900,
        body: Form(
          key: loginForm,
          child: SingleChildScrollView( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade500,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
                  ),
                  child: const Image(
                    image: AssetImage('images/splashLogo.png'),
                    height: 225,
                    width: 225,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container( 
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[ 
                      Text(
                        'Welcome',
                        style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.amber.shade500, height: 1.5),
                      ),
                      Text(
                        'Sukio Member',
                        style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.amber.shade500, height: 1.5),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05), 
                      const Text(
                        'Enter your registered phone number to access your account.',
                        style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01), 
                      TextFormField(
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
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          hintText: "Phone number",
                          prefixIcon: GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                countryListTheme: const CountryListThemeData(bottomSheetHeight: 600),
                                onSelect: (country) {
                                  setState(() {
                                    this.country = country;
                                  });
                                },
                              );
                            },
                            child:Container(
                              padding: const EdgeInsets.only(left: 10, right: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${country.flagEmoji} +${country.phoneCode}',
                                    style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            )
                          ), 
                          errorStyle: TextStyle(color: Colors.red.shade200), 
                        ), 
                      ), 
                      Visibility(
                        visible: emptyPhonErr.isNotEmpty,
                        child: Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: Text(emptyPhonErr, style: TextStyle(color: Colors.red.shade200))
                        )     
                      ),
                      Visibility(
                        visible: emptyPhonErr.isEmpty && phoneNotFoundErr.isNotEmpty,
                        child: Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: Text(phoneNotFoundErr, style: TextStyle(color: Colors.red.shade200))
                        )     
                      ),
                      Visibility(
                        visible: emptyPhonErr.isEmpty && phoneNotFoundErr.isEmpty && notApprove.isNotEmpty,
                        child: Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: Text(notApprove, style: TextStyle(color: Colors.red.shade200))
                        )     
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.016), 
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async { 
                            setState(() { noError = true; });
                            final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/login"), body: {
                              'phone_number': phoneNumberController.text,
                              'country_code': country.phoneCode,
                            });  
                            if (response.statusCode == 200) {
                              final Map<String, dynamic> res = json.decode(response.body);  

                              setState(() {
                                if (res['status'].toString() == 'false') {  
                                    emptyPhonErr = res['empty_phone'];
                                    notApprove = res['not_approved'];

                                    if (res['empty_phone'] == '') {
                                      phoneNotFoundErr = res['not_found'];
                                    }  
                                } else {   
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginOTP(
                                        phoneNumber: phoneNumberController.text,
                                        countryCode: country.phoneCode,
                                      ),
                                    ),
                                  );
                                } 
                                noError = false;
                              });
                            } else {
                              throw "Request failed with status: ${response.statusCode}";
                            } 
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
                                "Submit",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Register(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(text: "Not yet a Member? ", style: TextStyle(color: Colors.white70)),
                                  TextSpan(text: "Register", style: TextStyle(color: Colors.amber.shade500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final bool canAuthenticateWithBiometrics = await _biometricAuth.canCheckBiometrics;
                            print(canAuthenticateWithBiometrics);
                            final bool canAuthenticate = canAuthenticateWithBiometrics || await _biometricAuth.isDeviceSupported();
                            print(canAuthenticate);
                            final List<BiometricType> availableBiometrics = await _biometricAuth.getAvailableBiometrics();
                            print(availableBiometrics);
                            final bool didAuthenticate = await _biometricAuth.authenticate(
                              localizedReason: 'Please authenticate to show account balance',
                              authMessages: const <AuthMessages>[
                                AndroidAuthMessages(
                                  signInTitle: 'Oops! Biometric authentication required!',
                                  cancelButton: 'No thanks',
                                ),
                                IOSAuthMessages(
                                  cancelButton: 'No thanks',
                                ),
                              ],
                              options: const AuthenticationOptions()
                            );
                            print(didAuthenticate);
                            try {
                              print("<!-- THIS IS CALLED");
                              final bool didAuthenticate = await _biometricAuth.authenticate(
                                  localizedReason: 'Please authenticate to show account balance',
                                  authMessages: const <AuthMessages>[
                                    AndroidAuthMessages(
                                      signInTitle: 'Oops! Biometric authentication required!',
                                      cancelButton: 'No thanks',
                                    ),
                                    IOSAuthMessages(
                                      cancelButton: 'No thanks',
                                    ),
                                  ],
                                  options: const AuthenticationOptions());
                              print(didAuthenticate); 
                            } on PlatformException catch (e) {
                              if (e.code == auth_error.notEnrolled) {
                                print("<!-- THIS IS ERROR 1");
                                // Add handling of no hardware here.
                              } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
                                print("<!-- THIS IS ERROR 2");
                                // ...
                              } else {
                                print("<!-- THIS IS ERROR 3");
                                // ...
                              }
                            }
                        }, 
                        child: const Text('Face Id')
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ), 
      )
    ); 
  }  
}