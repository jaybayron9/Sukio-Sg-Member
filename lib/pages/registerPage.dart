import 'dart:convert';
import '/pages/loginPage.dart';
import '/pages/validationPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController groupController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Country country = CountryParser.parseCountryCode('SG'); 
  String countryCode = '';
  dynamic firstNameErr = '';
  dynamic lastNameErr = '';
  dynamic groupErr = '';
  dynamic phoneNumErr = '';
  dynamic emailErr = '';
  dynamic empEmailErr = '';
  dynamic invEmailErr = '';
  dynamic invPhoneErr = '';
  dynamic existPhoneErr = ''; 
  bool noError = false;

  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10)); 

  showErrorMsg(error1, {error2 = '', error3 = ''}) {
    if (error1 != '') {
      return Visibility(
        visible: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 22),
              child: Stack(
                children: [
                  Text(
                    error1,
                    style: TextStyle(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.white,
                    ),
                  ),
                  Text(
                    error1,
                    style: TextStyle(foreground: Paint()..color = Colors.red),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }
    if (error2 != '') {
      return Visibility(
        visible: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 22),
              child: Text(
                error2,
                style: const TextStyle(color: Colors.red),
              ),
            )
          ],
        ),
      );
    }

    if (error3 != '') {
      return Visibility(
        visible: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 22),
              child: Text(
                error3,
                style: const TextStyle(color: Colors.red),
              ),
            )
          ],
        ),
      );
    }

    return Visibility(
      visible: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900, 
      body: Form(
        child: SingleChildScrollView(
          child: Column(
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      alignment: Alignment.centerLeft, 
                      child: const Text(
                        'Register,',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft, 
                      child: const Text(
                        'Enter your details to create an account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // First name input
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white, 
                                  ), 
                                  child: TextFormField(
                                    controller: firstNameController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "First Name",
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: firstNameErr.isNotEmpty,
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child:  Container(
                                      margin: const EdgeInsets.only(left: 15),
                                      child: Text(firstNameErr, style: TextStyle(color: Colors.red.shade200))
                                    )     
                                  ),
                                ), 
                              ],
                            ),
                          ),
                        ), 
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.only(left: 10), 
                                  child: TextFormField(
                                    controller: lastNameController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Last Name",
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: firstNameErr.isNotEmpty,
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child:  Container(
                                      margin: const EdgeInsets.only(left: 15),
                                      child: Text(firstNameErr, style: TextStyle(color: Colors.red.shade200))
                                    )     
                                  ),
                                ),  
                              ],
                            ),
                          ),
                        ),
                      ], 
                    ), 
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        children: [
                          Container( 
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white, // Add a border
                            ), 
                            child: TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Email",
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: emailErr.isNotEmpty,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child:  Container(
                                margin: const EdgeInsets.only(left: 15),
                                child: Text(emailErr, style: TextStyle(color: Colors.red.shade200))
                              )     
                            ),
                          ), 
                          Visibility(
                            visible: emailErr.isEmpty && invEmailErr.isNotEmpty,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child:  Container(
                                margin: const EdgeInsets.only(left: 15),
                                child: Text(invEmailErr, style: TextStyle(color: Colors.red.shade200))
                              )     
                            ),
                          ),  
                        ],
                      ),
                    ),   
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white, 
                            ),  
                            child: TextFormField(
                              controller: phoneNumberController,
                              onFieldSubmitted: (phoneNumber) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text( '+${country.phoneCode}$phoneNumber')),
                                );
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Phone Number",
                                prefixIcon: GestureDetector(
                                  onTap: () { 
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
                                  },
                                  child: Container(
                                    height: 50,
                                    width: 78,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${country.flagEmoji} +${country.phoneCode}',
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
                          Visibility(
                            visible: phoneNumErr.isNotEmpty,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child:  Container(
                                margin: const EdgeInsets.only(left: 15),
                                child: Text(phoneNumErr, style: TextStyle(color: Colors.red.shade200))
                              )     
                            ),
                          ),  
                          Visibility(
                            visible: phoneNumErr.isEmpty && existPhoneErr.isNotEmpty,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child:  Container(
                                margin: const EdgeInsets.only(left: 15),
                                child: Text(existPhoneErr, style: TextStyle(color: Colors.red.shade200))
                              )     
                            ),
                          ),    
                        ], 
                      ),
                    ),   
                    SizedBox( 
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () async { 
                          setState(() { noError = true; });
                          try {
                            final response = await http.post(
                                Uri.parse("https://ww2.selfiesmile.app/members/register"),
                                body: {
                                  'first_name': firstNameController.text,
                                  'last_name': lastNameController.text,
                                  'phone_number': phoneNumberController.text,
                                  'email': emailController.text,
                                  'country_code': country.phoneCode
                                });
                
                            if (response.statusCode == 200) {
                              final Map<String, dynamic> res = json.decode(response.body);   
                              setState(() {
                                if (res['status'].toString() == 'false') { 
                                    firstNameErr = res['empty_fname'] ?? '';
                                    lastNameErr = res['empty_lname'] ?? '';
                                    emailErr = res['empty_email'] ?? '';
                                    phoneNumErr = res['empty_phone'] ?? ''; 
                                    if (res['empty_email'].toString() == '') {
                                      invEmailErr = res['invalid_email'] ?? '';
                                    } 
                                    if (res['empty_phone'].toString() == '') {
                                      existPhoneErr = res['number_exist'] ?? '';
                                    } 
                                } else { 
                                  firstNameErr = '';
                                  lastNameErr = '';
                                  emailErr = '';
                                  phoneNumErr = '';
                                  invEmailErr = '';
                                  invPhoneErr = '';
                                  existPhoneErr = '';
                                  firstNameErr = ''; 
                                  Navigator.push(context,
                                    MaterialPageRoute(
                                      builder: (context) => Verification(
                                        firstName: firstNameController.text,
                                        lastName: lastNameController.text,
                                        phoneNumber: phoneNumberController.text,
                                        email: emailController.text,
                                        countryCode: country.phoneCode,
                                      )
                                    ),
                                  );
                                }
                                 noError = false;
                              });
                            }
                          } catch (e) {
                            debugPrint("Error: $e");
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
                              "Register",
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
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: GestureDetector(
                        onTap: () { 
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(children: [
                            const TextSpan(
                              text: "Already a member ? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextSpan(
                              text: "Log-in",
                              style: TextStyle(color: Colors.amber.shade500),
                            ),
                          ]),
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
    );
  }
}
