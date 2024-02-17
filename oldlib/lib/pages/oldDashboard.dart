
// ignore_for_file: avoid_print

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardPage extends StatefulWidget { 
  final String? memberId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;  
  final String? role;

  const DashboardPage({
    Key? key, 
    this.memberId,
    this.firstName,
    this.lastName,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.role
  }) : super(key: key); 

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? scannedQRData; 

  static const IconData qr_code_scanner_rounded = IconData(0xf00cc, fontFamily: 'MaterialIcons');

  Future<void> _showScanResultDialog(String qrdata) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Result'),
          content: RichText(
            text: TextSpan(
              text: qrdata,
              style: const  TextStyle(color: Colors.black), 
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

  Future<void> _qrScanner() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) { 
      String? qrdata = await scanner.scan();
      if (qrdata != null) {
        setState(() {
          scannedQRData = qrdata; 
        });

        final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/inMember"), body: {
          'member_id': widget.memberId,
          'code': qrdata
        });

        if (res.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(res.body);
          print(responseData);

          await _showScanResultDialog(responseData['message'].toString());
        } 
      } else {
        print("User canceled the scan.");
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/memberLogs"), body: {
      'member_id': widget.memberId,
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

  @override
  void initState() {
    super.initState();
    print("DashboardPage is opened"); 
    print("memberId: ${widget.memberId}");
    print("firstName: ${widget.firstName}");
    print("lastName: ${widget.lastName}");
    print("email: ${widget.email}");
    print("countryCode: ${widget.countryCode}");
    print("phoneNumber: ${widget.phoneNumber}");
    print("role: ${widget.role}");
    print("scannedQRData: ${scannedQRData}"); 
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Specify the number of tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                    title: const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Welcome ' + widget.firstName! + ' ' + widget.lastName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () { 
                        print('CircleAvatar clicked!');
                      },
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('images/person.png'),
                      ),
                    ), 
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(
                    icon: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.black,
                          ),
                          SizedBox(width: 5), // Adjust the spacing between icon and text
                          Text(
                            'Check-in History',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    icon: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _DashboardPageState.qr_code_scanner_rounded,
                            color: Colors.black,
                          ),
                          SizedBox(width: 5), // Adjust the spacing between icon and text
                          Text(
                            'Scanner',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                labelColor: Colors.black,
                indicatorColor: Colors.orangeAccent,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(100)),
                ),
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData && snapshot.data != null) {
                            return DataTable(
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('In')),
                                DataColumn(label: Text('Out')),
                                DataColumn(label: Text('Date')),
                              ],
                              rows: snapshot.data!.map<DataRow>((record) {
                                return DataRow(cells: [
                                  DataCell(Text(record['id'])),
                                  DataCell(Text(record['check_in'].toString() == 'null' ? 'Not In' : record['check_in'])),
                                  DataCell(Text(record['check_out'].toString() == 'null' ? 'Not Out' : record['check_out'])),
                                  DataCell(Text(record['date'].toString() == 'null' ? '...' : record['date']))
                                ]);
                              }).toList(),
                            );
                          } else {
                            return const Center(child: Text('No data available'));
                          }
                        },
                      ), 
                    ),
                    Container(
                      key: const Key('Tab2Key'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: _qrScanner,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  iconSize: 40,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Click to Scan QR Code', // Your text label here
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
