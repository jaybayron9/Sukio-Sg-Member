import '/pages/login_page.dart';
import '/pages/validation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String countryCode = '';
  Country country = CountryParser.parseCountryCode('SG');

  dynamic firstNameErr = '';
  dynamic lastNameErr = '';
  dynamic groupErr = '';
  dynamic phoneNumErr = '';
  dynamic emailErr = '';
  dynamic empEmailErr = '';
  dynamic invEmailErr = '';
  dynamic invPhoneErr = '';
  dynamic existPhoneErr = '';
  String success = '';

  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10));

  showPicker() {
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

  Future<void> sendData() async {
    try {
      final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/register"),
          body: {'first_name': firstNameController.text, 'last_name': lastNameController.text, 'phone_number': phoneNumberController.text, 'email': emailController.text, 'country_code': countryCode});

      if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(res.body);

        print(responseData);

        if (responseData['status'].toString() == 'false') {
          setState(() {
            firstNameErr = responseData['empty_fname'] ?? '';
            lastNameErr = responseData['empty_lname'] ?? '';
            emailErr = responseData['empty_email'] ?? '';
            phoneNumErr = responseData['empty_phone'] ?? '';

            if (responseData['empty_email'].toString() == '') {
              invEmailErr = responseData['invalid_email'] ?? '';
            }

            if (responseData['empty_phone'].toString() == '') {
              invPhoneErr = responseData['invalid_phone'] ?? '';
            }
          });
        } else {
          setState(() {
            firstNameErr = '';
            lastNameErr = '';
            emailErr = '';
            phoneNumErr = '';
            invEmailErr = '';
            invPhoneErr = '';
            existPhoneErr = '';
            firstNameErr = '';
            success = 'Phone Verification Sent!';

            // Add a delay of 2 seconds before navigating to the new page
            Future.delayed(Duration(seconds: 2), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Verification(
                          first_name: firstNameController.text,
                          last_name: lastNameController.text,
                          phone_number: phoneNumberController.text,
                          email: emailController.text,
                          country_code: countryCode,
                        )),
              );
            });
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  showErrorMsg(error1, {error2 = '', error3 = ''}) {
    if (error1 != '') {
      return Visibility(
        visible: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 22),
              child: Text(
                error1,
                style: const TextStyle(color: Colors.red),
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
      body: SafeArea(
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 25, right: 25), // Align the text to the right within its container
                  child: Text(
                    'Register,',
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
                    'Enter your details to create an account.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Container(
                  margin: const EdgeInsets.only(left: 25, right: 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // First name input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey), // Add a border
                              ),
                              padding: const EdgeInsets.only(left: 10),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: firstNameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "First Name",
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: showErrorMsg(firstNameErr),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Last name input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey), // Add a border
                              ),
                              padding: const EdgeInsets.only(left: 10),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: lastNameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Last Name",
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: showErrorMsg(lastNameErr),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey), // Add a border
                        ),
                        padding: const EdgeInsets.only(left: 10),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Email",
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: showErrorMsg(emailErr, error2: invEmailErr),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey), // Add a border
                        ),
                        padding: const EdgeInsets.only(left: 10),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: phoneNumberController,
                          onFieldSubmitted: (phoneNumber) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('+${country.phoneCode}$phoneNumber')),
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
                              onTap: showPicker,
                              child: Container(
                                height: 55,
                                width: 100,
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
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20), // Adjust the top padding as needed
                    child: showErrorMsg(phoneNumErr, error2: invPhoneErr, error3: existPhoneErr),
                  ),
                ),
                Visibility(
                  visible: success != '' ? true : false,
                  child: Text(success, style: const TextStyle(color: Colors.green)),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                // Register Submit button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      countryCode = country.phoneCode;
                      sendData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),

                // Check in navigation
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigation logic to go to the LoginPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                          text: "Already a member ? ",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: "Check-in",
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ]),
                    ),
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
