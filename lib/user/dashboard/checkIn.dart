// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http; 
import 'package:permission_handler/permission_handler.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/auth/login.dart';
import 'package:url_launcher/url_launcher.dart';  

class CheckIn extends StatefulWidget {
  const CheckIn({ Key? key }) : super(key: key);

  @override
  _CheckInState createState() => _CheckInState();
}

class _CheckInState extends State<CheckIn> { 
  bool isClick = false;
  bool isCheckIn = false;
  String dateIn = '';
  String timeIn = '';
  String _debugLabelString = '';
  List<Map<String, dynamic>> memberLogsData = [];

  @override
  void initState() {
    super.initState(); 
    isNotCheckOut(); 
  }  

  isNotCheckOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/member/notify/is/not/checkout'), body: {
      'member_id': prefs.getString('authId').toString()
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['status'].toString() == 'true') { 
        Navigator.pushNamed(context, '/checkOut');  
      } else {
        setState(() { isCheckIn = true; });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/member/logs"), body: {
      'member_id': prefs.getString('authId').toString(),
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);

      return jsonResponse.map((e) => {
        'id': e['id'].toString(), 
        'check_in': e['check_in'], 
        'check_out': e['check_out'], 
        'date': e['date']
      }).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }  

  Future<void> _qrScanner() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      final qrdata = QrBarCodeScannerDialog();
      qrdata.getScannedQrBarCode(
        context: context,
        onCode: (String? value) async { 
          final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/member/in"), body: {
            'member_id': prefs.getString('authId').toString(), 
            'code': value, 
          });
          if (res.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(res.body);
            if (responseData['status'].toString() == 'true') {
              if (responseData['type'] == 'in') {
                triggerMasterCheckIn();  
              }
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.rightSlide,
                title: responseData['type'] == 'in' ? 'Checked In' : 'Checked Out',
                desc: responseData['message'], 
                dismissOnTouchOutside: false,
                btnOkOnPress: () async { 
                  if (responseData['type'] == 'in') {
                    setState(() {
                      isCheckIn = true;
                    });  
                    Navigator.pushNamed(context, '/checkOut'); 
                  } else if (responseData['type'] == 'out') {
                    setState(() {
                      isCheckIn = false;
                    });
                    Navigator.pushNamed(context, '/checkIn');  
                  }
                  getDateCheckIn();
                },
              ).show(); 
            } else {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: responseData['type'].toString() == 'in' ? 'Check-in Issue' : 'Check-out Issue',
                desc: responseData['message'], 
                dismissOnTouchOutside: false,
                btnOkColor: Colors.red,
                btnOkOnPress: () {},
              ).show(); 
            }
          }
        }
      );
    } else {
      var isGrant = await Permission.camera.request();
      if (isGrant.isGranted) {
        final qrdata = QrBarCodeScannerDialog();
        qrdata.getScannedQrBarCode(
          context: context,
          onCode: (String? value) async {
            final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/in"), body: {
              'member_id': prefs.getString('authId').toString(), 
              'code': value, 
            });
            if (res.statusCode == 200) {
              final Map<String, dynamic> responseData = json.decode(res.body);
              if (responseData['status'].toString() == 'true') {
                if (responseData['type'] == 'in') {
                  triggerMasterCheckIn();  
                }
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.rightSlide,
                  title: 'Checked In',
                  desc: responseData['message'], 
                  dismissOnTouchOutside: false,
                  btnOkOnPress: () { 
                    if (responseData['type'] == 'in') {
                      setState(() {
                        isCheckIn = true;
                      }); 
                      Navigator.pushNamed(context, '/checkOut'); 
                    } else if (responseData['type'] == 'out') {
                      setState(() {
                        isCheckIn = false;
                      });
                      Navigator.pushNamed(context, '/checkIn'); 
                    }
                    getDateCheckIn();
                  },
                ).show(); 
               } else {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.error,
                  animType: AnimType.rightSlide,
                  title: 'Check In Issue',
                  desc: responseData['message'], 
                  btnOkOnPress: () {},
                ).show(); 
              }
            }
          }
        );
      }
    }
  }

  Future<void> refreshAttendance() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/member/check/attendance/status'), body: {
      'member_id': prefs.getString('authId').toString()
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> res = json.decode(response.body); 
      setState(() {
        isNotCheckOut();
        if (res['status'].toString() == 'false') { 
          isCheckIn = false;
        } else {
          isCheckIn = true;
        }
      });
    }

    List<Map<String, dynamic>> newData = await fetchData();  
    setState(() { memberLogsData = newData; }); 
  }

  triggerMasterCheckIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    await http.post(Uri.parse("https://ww2.selfiesmile.app/member/trigger/in"), body: {
      "name": '${prefs.getString('firstName').toString()} ${prefs.getString('lastName').toString()}',
    });
  }

  getDateCheckIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/member/get/in/date/time"), body: {
      'member_id': prefs.getString('authId').toString(),
    }); 
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body); 
      setState(() {
        dateIn = responseData['date'].toString();
        timeIn = responseData['check_in'].toString();
      }); 
    } else {
      throw Exception('Failed to load data');
    }
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
      },
      child: Scaffold(
        body: Container(
          color: Colors.blue.shade900,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const Image(
                        image: AssetImage('images/sukioMahikari.png'),
                        height: 130,
                        width: 130,
                        fit: BoxFit.cover,
                      ), 
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
                            foregroundColor: MaterialStateProperty.all<Color>(const Color(0xFF222222)),
                            overlayColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return const Color(0xFFDDDDDD);
                                }
                                return const Color(0xFFDDDDDD);
                              },
                            ),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                            padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(13)),
                            textStyle: MaterialStateProperty.all<TextStyle>(
                              const TextStyle(
                                fontFamily: 'Circular',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                          onPressed: () async { 
                            setState(() { isClick = true; }); 
                            _qrScanner(); 
                            setState(() { isClick = false; });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_outlined,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CHECK IN',
                                style: TextStyle(
                                  fontFamily: 'Circular',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              Visibility(
                                visible: isClick,
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
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse('https://www.itfs.org.sg')); 
                        },
                        child: const Image(
                          image: AssetImage('images/logoitfs.png'),
                          height: 40, 
                          fit: BoxFit.cover,
                        ), 
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'A CSR program of ', 
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12
                            )
                          ),
                          GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse('https://www.cal4care.com/company/social-responsibility/'));
                            },
                            child: const Text('Cal4care Group', 
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white, 
                                decorationColor: Colors.white,
                                decoration: TextDecoration.underline,
                              )
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0.0, 1.0), //(x,y)
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            height: 400,
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.blue.shade500),
                            ),
                          );
                        }
        
                        return DataTable(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
                          ),
                          columns: const [
                            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('IN', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('OUT', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: snapshot.data!.asMap().entries.map<DataRow>((entry) {
                            final record = entry.value;
        
                            return DataRow(
                              cells: [
                                DataCell(Text(record['id'].toString() == '0' ? '---' : record['id'])),
                                DataCell(Text(record['check_in'].toString() == 'null' ? '---' : record['check_in'])),
                                DataCell(Text(record['check_out'].toString() == 'null' ? '---' : record['check_out'])),
                                DataCell(Text(record['date'].toString() == 'null' ? '---' : record['date']))
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              )
            ],
          ), 
        ),
        floatingActionButton: SizedBox(
          width: 38,
          height: 38,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: FloatingActionButton(
              onPressed: () {
                refreshAttendance();
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: const Icon(Icons.refresh),
            ),
          ),
        ), 
      ), 
    );
  }
}