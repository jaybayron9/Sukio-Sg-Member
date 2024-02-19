// import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/pages/login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/checkCookie.dart';

class DashboardPage extends StatefulWidget {
  final String? memberId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;
  final String? role;
  final String? qrCode;

  const DashboardPage({Key? key, this.memberId, this.firstName, this.lastName, this.email, this.countryCode, this.phoneNumber, this.role, this.qrCode}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // check if session is already saved, check
  // contact with index start call, based if rerepose auth or not,
  // if auth, forward dashboard page
  // if not auth, stay login

  String? scannedQRData;
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  Future<List<Map<String, dynamic>>> fetchData() async {
    final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/memberLogs"), body: {
      'member_id': widget.memberId,
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);

      return jsonResponse.map((e) => {'id': e['id'].toString(), 'check_in': e['check_in'], 'check_out': e['check_out'], 'date': e['date']}).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _qrScanner() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      String? qrdata = await scanner.scan();
      if (qrdata != null) {
        setState(() {
          scannedQRData = qrdata;
        });

        final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/inMember"), body: {'member_id': widget.memberId, 'code': qrdata});

        if (res.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(res.body);

          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Scan Result'),
                content: RichText(
                  text: TextSpan(
                    text: responseData['message'].toString(),
                    style: const TextStyle(color: Colors.black),
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
      }
    }
  }

  String imageUrl = ''; 
  Future<void> freshQR() async {
    final res = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/newQR'), body: {'member_id': widget.memberId});

    if (res.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(res.body);

      print(responseData);

      setState(() {
        imageUrl = 'https://ww2.selfiesmile.app/img/qrcodes/' + responseData['img'].toString();
      });
    }
  }

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('member_id');
  }

  Future<void> deleteFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('member_id');
  } 

  @override
  void initState() {
    super.initState(); 

    getFromLocalStorage().then((storedValue) {
      if (storedValue != null) { 
        print('Value from Local Storage: $storedValue');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        ); 
        print('Value not found in Local Storage.');
      }
    });

    imageUrl = 'https://ww2.selfiesmile.app/img/qrcodes/member_${widget.memberId}_${widget.qrCode}.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _qrScanner,
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: const Text(
                      'Welcome to Sokyu Mahikari!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 15),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('images/person.png'),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 10),
                          child: Text(
                            '${widget.firstName!} ${widget.lastName!}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Group'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('QR'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                deleteFromLocalStorage();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _widgetOptions {
    return [
      // Attendance
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('In')),
                    DataColumn(label: Text('Out')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: snapshot.data!.map<DataRow>((record) {
                    return DataRow(cells: [
                      DataCell(Text(record['id'].toString() == '0' ? '---' : record['id'])),
                      DataCell(Text(record['check_in'].toString() == 'null' ? '---' : record['check_in'])),
                      DataCell(Text(record['check_out'].toString() == 'null' ? '---' : record['check_out'])),
                      DataCell(Text(record['date'].toString() == 'null' ? '---' : record['date']))
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ), 
      // Group Calendar
      const Text(
        'Member Callendar',
        style: optionStyle,
      ),
      const Text(
        'Notifications',
        style: optionStyle,
      ), 
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
              child: Container(
            margin: const EdgeInsets.only(top: 40),
            child: Image.network(
              imageUrl,
              width: 400,
              height: 400,
            ),
          )),
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: ElevatedButton(
                onPressed: () {
                  freshQR();
                },
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                )),
          ),
        ],
      ),
      const Text(
        'Settings',
        style: optionStyle,
      ), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
