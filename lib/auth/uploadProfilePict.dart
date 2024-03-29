// ignore_for_file: use_build_context_synchronously

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/app.dart'; 
import 'package:sukio_member/auth/login.dart';
import 'dart:convert'; 
import 'package:sukio_member/auth/register.dart';
import 'package:sukio_member/utils/registerUser.dart';
import 'package:sukio_member/utils/user.dart';   

class UploadProfilePict extends StatefulWidget {
  const UploadProfilePict({ Key? key }) : super(key: key);

  @override
  _UploadProfilePictState createState() => _UploadProfilePictState();
}

class _UploadProfilePictState extends State<UploadProfilePict> {
  Map<String, String?> user = {};
  String image = 'defaultprofile.png';
  bool isLoading = false;
  bool hasImage = false;  

  @override
  void initState() {
    super.initState(); 
    userData();
  }

  userData() async {
    Map<String, String?> userData = await User.getUser(); 
    setState(() {
      user =  userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.blue.shade900, 
      ),
      backgroundColor: Colors.blue.shade900,
      body: Container(
        color: Colors.blue.shade900,
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Container( 
                margin: const EdgeInsets.symmetric(horizontal: 30),
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(200)),
                   boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 4, 55, 94).withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),  
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage:  NetworkImage(
                    'https://ww2.selfiesmile.app/img/profiles/$image',
                  ),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15), 
            SizedBox(
              width: 210,
              child: ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  if (result != null) {
                    var url = Uri.parse('https://ww2.selfiesmile.app/member/upload/profile');
                    var request = http.MultipartRequest('POST', url)
                      ..files.add(await http.MultipartFile.fromPath('file', result.files.single.path!));
                      request.fields['member_id'] = user['authId'].toString();  

                    var streamedResponse = await request.send();
                    var response = await http.Response.fromStream(streamedResponse); 
                    var responseData = json.decode(response.body);

                    if (response.statusCode == 200) {
                      setState(() {
                        image = responseData['img'].toString();
                        hasImage = true;
                        prefs.setString('profilePicture', responseData['img'].toString());
                      });
                    }
                  }
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Select Profile Picture",
                      style: TextStyle(fontSize: 15, color: Colors.blue.shade900),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.image_outlined, color: Colors.blueGrey)
                  ],
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await User.removeUser();
                          Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
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
                              "Cancel",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ), 
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: hasImage ? 30: 0),
                    Visibility(
                      visible: hasImage,
                      child: Expanded(
                        child: ElevatedButton(
                          onPressed: () async { 
                            Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => const App()),
                            );
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
                                "Continue",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                              const Visibility(
                                visible: false,
                                child: Row(
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
                    ),
                  ],
                ),
              ),
            ) 
          ],
        ),
      )
    );
  }
}