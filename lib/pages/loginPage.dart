// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously
import 'dart:convert';
import '/pages/assets.dart';
import '/pages/registerPage.dart';
import '/pages/dashboardPage.dart';
import '/pages/uniqueCodePage.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:country_picker/country_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {  
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
    getFromLocalStorage().then((storedValue) {
      if (storedValue != null) {
        auth(storedValue.toString());
      }
    });
  } 

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authId');
  }

  Future<void> auth(memberId) async {
    final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/auth"), body: {'member_id': memberId});
    if (res.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(res.body);
      print(responseData);
      if (responseData['status'].toString() == 'true') { 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              memberId: responseData['member_id'],
              membershipId: responseData['membership_id'],
              firstName: responseData['first_name'],
              lastName: responseData['last_name'],
              email: responseData['email'],
              countryCode: responseData['country_code'],
              phoneNumber: responseData['phone_number'],
              role: responseData['role'],
              qrCode: responseData['qr'],
              group: responseData['group'],
            ),
          ),
        );
      } else { 
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove('member_id'); 
      }
    }
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
                        'Enter your register phone number to access your account.',
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
                            child: Container(
                              height: 45,
                              width: 70,
                              alignment: Alignment.center,
                              child: Text(
                                '${country.flagEmoji} +${country.phoneCode}',
                                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
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
                                      builder: (context) => UniqueCode(
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
                                builder: (context) => const RegisterPage(),
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
