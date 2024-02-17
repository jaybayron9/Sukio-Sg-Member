// ignore_for_file: camel_case_types, avoid_print, constant_identifier_names, use_rethrow_when_possible

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;



class qrCodePage extends StatefulWidget {
  const qrCodePage({
    Key? key,

  }) : super(key: key);

  @override
  State<qrCodePage> createState() => _qrCodePageState();
}

class _qrCodePageState extends State<qrCodePage> { 
  String? scannedQRData; 

  Future<void> _qrScanner() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) { 
        String? qrdata = await scanner.scan();
        if (qrdata != null) {
          setState(() {
            scannedQRData = qrdata;  
          });
          print("Scanned QR Code: $qrdata"); 
        } else {
          print("User canceled the scan.");
        } 
    } else {
      var isGrant = await Permission.camera.request();
      if (isGrant.isGranted) { 
        String? qrdata = await scanner.scan();
        if (qrdata != null) {
          setState(() {
            scannedQRData = qrdata;  
          });
          print("Scanned QR Code: $qrdata"); 
        } else {
          print("User canceled the scan.");
        } 
      }
    }
  }

  static const IconData qr_code_scanner_rounded = IconData(0xf00cc, fontFamily: 'MaterialIcons');

  Future<Map<String, dynamic>> qrfetch() async { 
    final response = await http.get(Uri.parse("https://ww2.selfiesmile.app/members/getUser"));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      print("Failed to load data. Status code: ${response.statusCode}");
      throw Exception("Failed to load data. Status code: ${response.statusCode}");
    } 
  } 

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TAB BAR'),
        ),
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.qr_code,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                Tab(
                  icon: Icon(
                    _qrCodePageState.qr_code_scanner_rounded,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder(
                    future: qrfetch(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        print("Error: ${snapshot.error}");
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else {
                        if (snapshot.data!.containsKey("id") && snapshot.data!.containsKey("qr_code")) {
                          String qrCodeUrl = 'https://ww2.selfiesmile.app/img/qrcodes/member' +
                              '_' +
                              snapshot.data?["id"] +
                              '_' +
                              snapshot.data?["qr_code"] +
                              '.png';

                          print("Image URL: $qrCodeUrl");

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    qrCodeUrl,
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10), // Adjust the spacing as needed
                              const Text(
                                "Scan the code to easily Check-in ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          );
                        } else {
                          print("Invalid response format");
                          return const Center(child: Text("Invalid response format"));
                        }
                      }
                    },
                  ), 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (scannedQRData != null)
                        Text(
                          "Scanned QR Code: $scannedQRData",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _qrScanner();
                          },
                          child: const Text('SCAN QR CODE'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
