// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use, unnecessary_constructor_name, unnecessary_import, unused_field

import 'dart:convert';  
import 'package:awesome_dialog/awesome_dialog.dart'; 
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '/pages/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';  

class Event {
  final String title;
  final DateTime date;

  Event(this.title, this.date);
}

class DashboardPage extends StatefulWidget {
  final String? memberId;
  final String? membershipId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;
  final String? role;
  final String? qrCode;
  final String? group;

  const DashboardPage({Key? key, this.memberId, this.membershipId, this.firstName, this.lastName, this.email, this.countryCode, this.phoneNumber, this.role, this.qrCode, this.group}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month; 
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<GroupEvent> events = [];
  List<GroupEvent> filteredEvents = [];
  String dateIn = '';
  String timeIn = '';
  bool isCheckIn = false; 
  bool hasCheckOut = false;
  bool hasQR = false;  
  String? scannedQRData;
  int _selectedIndex = 0;   
  String _debugLabelString = ""; 
  String locationName = '';
  double latitude = 0;
  double longtitude = 0;  
  bool isClick = false; 
  List<Map<String, dynamic>> memberLogsData = []; 

  @override
  void initState() {
    super.initState();  
    checkAccountStatus();   
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose); 
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(false); 
    OneSignal.initialize('df33667d-80b5-4062-9ccb-2325537fa02e');  
    OneSignal.Notifications.clearAll(); 
    OneSignal.User.pushSubscription.addObserver((state) async { 
      final res = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/saveSubscriptionId'), body: { 
        'member_id': widget.memberId, 'subscription_id': OneSignal.User.pushSubscription.id.toString()
      });

      if (res.statusCode == 200) { 
        // final Map<String, dynamic> responseData = json.decode(res.body);
        // print(responseData);
      }
    }); 
    OneSignal.Notifications.addPermissionObserver((state) async { 
      await http.post(Uri.parse('https://ww2.selfiesmile.app/members/saveSubscriptionId'), body: { 
        'member_id': widget.memberId, 'subscription_id': OneSignal.User.pushSubscription.id.toString()
      });
      // print("Has permission " + state.toString());
    }); 
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
      checkAccountStatus();
      fetchGroupEvents(widget.memberId.toString(), widget.group.toString()).then((result) { 
        setState(() {
          events = result; 
          // _onItemTapped(1);
        });
      });
      setState(() {
        _debugLabelString = "Clicked notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    }); 
    OneSignal.Notifications.requestPermission(true);
    // OneSignal.Location.requestPermission();

    isNotCheckOut();
    userSettings();
    setLocation();
    getFromLocalStorage().then((storedValue) {
      if (storedValue == null) {
        debugPrint('Value from Local Storage: $storedValue');
      } else { 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
        debugPrint('Value not found in Local Storage.');
        deleteFromLocalStorage();
      }
    });
    imageUrl = 'https://ww2.selfiesmile.app/img/qrcodes/member_${widget.memberId}_${widget.qrCode}.png';
    fetchGroupEvents(widget.memberId.toString(), widget.group.toString()).then((result) {
      setState(() {
        events = result; 
      });
    }); 
    websocket();
  } 

  websocket() async {
    final pusher = PusherChannelsFlutter.getInstance();
    await pusher.init(
      apiKey: '4d42882071c5e763a2af',
      cluster: 'ap1'
    );
    await pusher.subscribe(
      channelName: "account-status",
      onEvent: (event) { 
        print("Got channel event: $event");  
        checkAccountStatus();
        refreshEventsCalendar();
      }
    );
    await pusher.connect(); 
  }

  Future<bool> setLocation() async {
    LocationPermission permission = await Geolocator.checkPermission(); 
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled(); 
      if (isLocationServiceEnabled) { 
        Position position = await Geolocator.getCurrentPosition(); 
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) { 
          setState(() {
            latitude = position.latitude;
            longtitude = position.longitude;
            locationName = placemarks[0].name ?? 'Unknown Location';
          }); 
          return true;
        } 
      } 
    }
    return false;
  }

  Future<bool> checkLocationStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (isLocationServiceEnabled) {
        try {
          Position position = await Geolocator.getCurrentPosition(); 
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          
          if (placemarks.isNotEmpty) { 
            setState(() {
              latitude = position.latitude;
              longtitude = position.longitude;
              locationName = placemarks[0].name ?? 'Unknown Location';
            }); 
            return true;
          } else {
            // print('Unable to retrieve location name.');
            return false;
          }
        } catch (e) {
          // print('Error getting location: $e');
          return false;
        }
      } else {
        // print('Location service is not enabled. Opening location settings...');
        Geolocator.openLocationSettings();
        return false;
      }
    } else {
      // print('Location permission is not granted. Requesting permission...');
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) { 
        return await checkLocationStatus(); 
      } else {
        // print('Location permission denied.'); 
        return false;
      }
    }
  } 

  Future<void> _qrScanner() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      final qrdata = QrBarCodeScannerDialog();
      qrdata.getScannedQrBarCode(
        context: context,
        onCode: (String? value) async { 
          final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/inMember"), body: {
            'member_id': widget.memberId, 
            'code': value,
            'latitude': latitude.toString(),
            'longtitude': longtitude.toString(),
            'location_name': locationName.toString()
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
                    _onItemTapped(5);
                  } else if (responseData['type'] == 'out') {
                    setState(() {
                      isCheckIn = false;
                    });
                    _onItemTapped(0);
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
            final res = await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/inMember"), body: {
              'member_id': widget.memberId, 
              'code': value,
              'latitude': latitude.toString(),
              'longtitude': longtitude.toString(),
              'location_name': locationName.toString()
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
                      _onItemTapped(5);
                    } else if (responseData['type'] == 'out') {
                      setState(() {
                        isCheckIn = false;
                      });
                      _onItemTapped(0);
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

  Future<void> checkAccountStatus() async {
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/checkAccountStatus'), body: {
      'member_id': widget.memberId
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> res = json.decode(response.body);

      if (res['status'].toString() == 'false') {
        await AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          dismissOnTouchOutside: false,
          btnOkColor: Colors.red,
          title: 'Account Status',
          desc: res['message'], 
          btnOkOnPress: () { 
            deleteFromLocalStorage(); 
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
        ).show(); 
        deleteFromLocalStorage(); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
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

  Future<void> refreshAttendance() async { 
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/checkAttStat'), body: {
      'member_id': widget.memberId
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> res = json.decode(response.body); 
      setState(() {
        isNotCheckOut();
        if (res['status'].toString() == 'false') {
          _onItemTapped(0);
          isCheckIn = false;
        } else {
          isCheckIn = true;
        }
      });
    }

    List<Map<String, dynamic>> newData = await fetchData();  
    setState(() { memberLogsData = newData; }); 
  }

  String imageUrl = '';
  Future<void> freshQR() async {
    final res = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/newQR'), body: {'member_id': widget.memberId});
    if (res.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(res.body);
      // print(responseData);
      setState(() {
        imageUrl = 'https://ww2.selfiesmile.app/img/qrcodes/${responseData['img']}';
      });
    }
  }

  Future<String?> getFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('member_id');
  }

  Future<void> deleteFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('authId');
  }

  bool _hasEventsForDay(DateTime day) {
    return events.any((event) => isSameDay(event.date, day));
  }

  Future<List<GroupEvent>> fetchGroupEvents(String memberId, String group) async {
    final response = await http.post(
      Uri.parse('https://ww2.selfiesmile.app/members/getGroupEvents'),
      body: {'member_id': memberId, 'group': group},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // print(data);

      List<GroupEvent> groupEventsList = data.map((event) => GroupEvent.fromJson(event)).toList();

      return groupEventsList;
    } else {
      throw Exception('Failed to load group events');
    }
  }

  refreshEventsCalendar() {
    fetchGroupEvents(widget.memberId.toString(), widget.group.toString()).then((updatedEvents) {
      setState(() {
        events = updatedEvents; 
        filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
      });
    }); 
  }

  getDateCheckIn() async {
    final response = await http.post(Uri.parse("https://ww2.selfiesmile.app/members/getCheckInDateTime"), body: {
      'member_id': widget.memberId,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      setState(() {
        dateIn = responseData['date'].toString();
        timeIn = responseData['check_in'].toString();
      });

      // print(responseData);
    } else {
      throw Exception('Failed to load data');
    }
  }

  requestCheckOut() async {
    final response = await http.post(
      Uri.parse('https://ww2.selfiesmile.app/attendance/requestOut'),
      body: {'member_id': widget.memberId},
    ); 
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      // print(responseData); 
      if (responseData['status'].toString() == 'true') {
        _onItemTapped(0);
      }
    }
  }

  userSettings() async {
    final response = await http.post(
      Uri.parse('https://ww2.selfiesmile.app/settings/userSettings'),
      body: {'member_id': widget.memberId}
    ); 
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);  
      if (responseData['status'].toString() == 'true') { 
        setState(() {
          hasCheckOut = responseData['check_out_request'].toString() == '1' ? true : false; 
          hasQR = responseData['show_qr'].toString() == '1' ? true : false; 
        });
      }
    }
  }

  isNotCheckOut() async {
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/isNotCheckOut'), body: {'member_id': widget.memberId});

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['status'].toString() == 'true') {
        _onItemTapped(5);
        setState(() {
          isCheckIn = true;
          dateIn = responseData['date'].toString();
          timeIn = responseData['in'].toString();
        });
      } else {
        _onItemTapped(0);
      }
    }
  }

  triggerMasterCheckIn() async {
    await http.post(Uri.parse("https://ww2.selfiesmile.app/attendance/triggerCheckIn"), body: {
      "name": '${widget.firstName} ${widget.lastName}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope.new(
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
        appBar: AppBar(
          backgroundColor: Colors.blue.shade900,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            const Spacer(),
            Row(
              children: [
                // Indicator
                Container(
                  height: 10,
                  width: 10,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: isCheckIn ? Colors.green : Colors.white70,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(20.0),
                    ),
                  ),
                ),
                // Refresh button for check-out/check-in
                Visibility(
                  visible: _selectedIndex == 0 || _selectedIndex == 5,
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: IconButton(
                      onPressed: (){
                        userSettings();
                        refreshAttendance();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
                // Refresh button for events 
                Visibility(
                  visible: _selectedIndex == 1,
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: IconButton(
                      onPressed: (){
                        fetchGroupEvents(widget.memberId.toString(), widget.group.toString()).then((updatedEvents) {
                          setState(() {
                            events = updatedEvents; 
                            filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
                          });
                        }); 
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                )
              ],
            ),
          ],
        ), 
        body: _widgetOptions[_selectedIndex], 
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: const Text(
                        'Welcome to Sukio Mahikari!',
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.firstName!} ${widget.lastName!}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                Text(
                                  'ID: ${widget.membershipId!}',
                                  style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ) 
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _selectedIndex == 0,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await checkAccountStatus();
                  isNotCheckOut();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Events'),
                trailing: const Icon(Icons.arrow_forward_ios),
                selected: _selectedIndex == 1,
                onTap: () async {
                  await checkAccountStatus();
                  refreshEventsCalendar();
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   title: const Text('Notifications'),
              //   selected: _selectedIndex == 2,
              //   onTap: () async {
              //     await checkAccountStatus();
              //     _onItemTapped(2);
              //     Navigator.pop(context);
              //   },
              // ),
              // Visibility(
              //   visible: hasQR,
              //   child: ListTile(
              //     leading: const Icon(Icons.qr_code),
              //     trailing: const Icon(Icons.arrow_forward_ios),
              //     title: const Text('QR Code'),
              //     selected: _selectedIndex == 3,
              //     onTap: () async {
              //       await checkAccountStatus();
              //       _onItemTapped(3);
              //       Navigator.pop(context);
              //     },
              //   ),
              // ),
              ListTile(
                leading: const Icon(Icons.book),
                trailing: const Icon(Icons.arrow_forward_ios),
                title: const Text('eBooks'),
                selected: _selectedIndex == 6,
                onTap: () async {
                  await checkAccountStatus();
                  _onItemTapped(6);
                  Navigator.pop(context);
                },
              ), 
              // ListTile(
              //   title: const Text('Settings'),
              //   onTap: () async {
              //     await checkAccountStatus();
              //     _onItemTapped(4);
              //     Navigator.pop(context);
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.temple_buddhist),
                selected: _selectedIndex == 7,
                title: const Text('About Us'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await checkAccountStatus();
                  _onItemTapped(7);
                  Navigator.pop(context);
                }
              ), 
              ListTile(
                leading: const Icon(Icons.diversity_1),
                selected: _selectedIndex == 8,
                title: const Text('About ItFS'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await checkAccountStatus();
                  _onItemTapped(8);
                  Navigator.pop(context);
                }
              ), 
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  deleteFromLocalStorage(); 
                  Navigator.pushReplacement(
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
      )
    );
  }

  List<Widget> get _widgetOptions {
    return [
      // Attendance
      Container(
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
                          await checkAccountStatus();
                          bool status = await checkLocationStatus();  
                          if (status) _qrScanner(); 
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
                        return const SizedBox(
                          height: 400, // Ensure the container takes full height
                          child: Center(
                            child: CircularProgressIndicator(),
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
      // Group Calendar
      Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime.now();
                    });
                  },
                  child: const Text('Today', style: TextStyle(color: Colors.black, fontSize: 15)),
                ),
              ],
            ),
          ),
          TableCalendar(
            calendarFormat: _calendarFormat,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            onFormatChanged: (format) { 
              setState(() {
                _calendarFormat = format;
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay; 
                filteredEvents = events.where((event) => isSameDay(event.date, selectedDay)).toList();
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                bool hasEvents = _hasEventsForDay(date);
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEvents ? Colors.blue : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: hasEvents ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredEvents.isEmpty
              ? const Center(
                  child: Text(
                    'No event(s)',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    GroupEvent event = filteredEvents[index];
                    return ExpansionTile(
                      title: Text(event.eventTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Date: '),
                              Text('${event.eventDate} ',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              const Text('Time: '),
                              Text('${event.time} ',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(event.descriptionText),
                        ],
                      ),
                      children: const <Widget>[
                        // You can add additional widgets here to display additional information when expanded
                      ],
                    );
                  },
                ),
          ),
        ],
      ), 
      // Notifications
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(left: 15),
              child: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Text(
            //   'You have new notifications!',
            //   style: TextStyle(
            //     fontSize: 16,
            //   ),
            // ),
            NotificationCard(
              title: 'Event Reminder',
              message: 'Description of the event.',
              date: '2024-02-28',
              time: '10:30 AM',
            ),
          ],
        ),
      ),
      // QR
      Visibility(
        visible: hasQR,
        child: Column(
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
      ),
      // Settings
      ListView(
        children: [
          ListTile(
            title: const Text('Notification Settings'),
            subtitle: const Text('Configure notification preferences'),
            leading: const Icon(Icons.notifications),
            onTap: () {
              // Handle tap for notification settings
            },
          ),
          ListTile(
            title: const Text('Account Settings'),
            subtitle: const Text('Manage your account details'),
            leading: const Icon(Icons.account_circle),
            onTap: () {
              // Handle tap for account settings
            },
          ),
          // Add more ListTiles for additional settings
        ],
      ),
      // Checked Out Page
      Container(
        color: Colors.blue.shade900,
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [  
                  const SizedBox(height: 10),
                    Image(
                    image: const AssetImage('images/sukioMahikari.png'),
                    height: hasCheckOut ? 96 : 130,
                    width: hasCheckOut ? 96 : 130,
                    fit: BoxFit.cover,
                  ), 
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.amber.shade500),
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
                            side: BorderSide(color: Colors.blue.shade900),
                          ),
                        ),
                        padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(13)),
                        textStyle: MaterialStateProperty.all<TextStyle>(
                          TextStyle(
                            fontFamily: 'Circular',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      onPressed: () async { 
                        setState(() { isClick = true; });
                        bool status = await checkLocationStatus();  
                        if (status) _qrScanner(); 
                        setState(() { isClick = false; });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.blue.shade900,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CHECK OUT',
                            style: TextStyle(
                              fontFamily: 'Circular',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade900,
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
                  SizedBox(height: hasCheckOut ? 8 : 0),
                  Visibility(
                    visible: hasCheckOut,
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.amber.shade500),
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
                              side: BorderSide(color: Colors.blue.shade900),
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
                        onPressed: () {
                          requestCheckOut(); 
                          setState(() { isCheckIn = false; });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_num_outlined,
                              color: Colors.blue.shade900, 
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'REQUEST CHECK OUT',
                              style: TextStyle(
                                fontFamily: 'Circular',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have checked in to the center',
                    style: TextStyle(
                      color: Colors.orange.shade500,
                      fontWeight: FontWeight.w400,
                      fontSize: 18
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Center(
                        child: Text(
                          'Date : ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      ),
                      Center(
                        child: Text(
                          dateIn,
                          style: TextStyle(color: Colors.orange.shade500, fontSize: 16),
                        )
                      ),  
                      const SizedBox(width: 10), 
                      const Center(
                        child: Text(
                          'Time : ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      ),
                      Center(
                        child: Text(
                          timeIn,
                          style: TextStyle(color: Colors.orange.shade500, fontSize: 16),
                        ) 
                      ), 
                    ],
                  ), 
                  const SizedBox(height: 5),
                  Center( 
                    child: Row( 
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Center(
                          child: Text(
                            'Location: ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          )
                        ),
                        Center(
                          child: Text(
                            locationName,
                            style: TextStyle(color: Colors.orange.shade500, fontSize: 16),
                          )
                        ),  
                      ]
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse('https://www.itfs.org.sg')); 
                    },
                    child: Image(
                      image: const AssetImage('images/logoitfs.png'),
                      height: hasCheckOut ? 30 : 40, 
                      fit: BoxFit.cover,
                    ), 
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('A CSR program of ', style: TextStyle(color: Colors.white, fontSize: hasCheckOut ? 10 : 12)),
                      GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse('https://www.cal4care.com/company/social-responsibility/'));
                        },
                        child: Text('Cal4care Group', 
                          style: TextStyle(
                            fontSize: hasCheckOut ? 10 : 12,
                            color: Colors.white, 
                            decorationColor: Colors.white,
                            decoration: TextDecoration.underline,
                          )
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              )
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
                        return const SizedBox(
                          height: 400,
                          child: Center(
                            child: CircularProgressIndicator(),
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
        )
      ),       
      // eBooks 
      const Center( 
          child: Text('Coming soon...', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 150, 154, 153))) 
      ),
      // About Us
      Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              const Color.fromARGB(255, 62, 158, 236),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ListView(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                        image: AssetImage("images/sukioMahikari.png"),
                        fit: BoxFit.fill,
                      )),
                      margin: const EdgeInsets.only(bottom: 20),
                      alignment: Alignment.center,
                      child: const Image(
                        image: AssetImage('images/sukioMahikari.png'),
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                    const Text('About Sokio Mahikari',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 15),
                    const Text(
                      'Sukyo Mahikari is a spiritual organization that was founded in Japan in 1959 by Yoshikazu Okada. The name Sukyo Mahikari translates to "Universal Principles of Light and True Light" and is centered around the belief in the existence of a universal force called the "Divine Light." The main goal of Sukyo Mahikari is to help individuals to achieve spiritual growth and to contribute to the betterment of society through the practice of purification and the giving and receiving of light.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Central to the teachings of Sukyo Mahikari is the understanding of the importance of maintaining a spiritual balance in one\'s life. Members are encouraged to practice purification through the daily act of giving and receiving light as a means to cleanse their spiritual bodies and achieve a greater connection with the Divine Light. This practice is believed to promote physical and emotional well-being as well as spiritual enlightenment.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Sukyo Mahikari has established centers all over the world where individuals can participate in regular light-giving and receiving sessions, study the teachings of the organization, and participate in community service activities.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Overall, Sukyo Mahikari provides a spiritual path for individuals seeking to find meaning and harmony in their lives through the practice of purification and the pursuit of spiritual enlightenment.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse('http://sukyomahikari.asia'));
                          },
                          child: const Text(
                            'http://sukyomahikari.asia',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 7, 95, 218),
                            ),
                          ),
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // About ITFS
      Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              const Color.fromARGB(255, 62, 158, 236),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        alignment: Alignment.center,  
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse('https://www.itfs.org.sg')); 
                          },
                          child: const Image(
                            image: AssetImage('images/logoitfs.png'),
                            height: 65,  
                            fit: BoxFit.cover,
                          ), 
                        ),
                      ),  
                      const SizedBox(height: 10),
                      Text(
                        'About ITFS', 
                        textAlign: TextAlign.left, 
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade500,
                          decorationColor: Colors.orange.shade500,
                          decoration: TextDecoration.underline,
                        ) 
                      ), 
                      const SizedBox(height: 5),
                      const Text(
                        'Information Technology Foundation Singapore (ITFS) is a unique and pioneering organization in Singapore, dedicated to addressing the digital divide within our society. As the first technology foundation of its kind in the country, ITFS is committed to providing essential technology education and hands-on training to individuals who have been less fortunate in receiving such opportunities in the past.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ), 
                      const SizedBox(height: 20),
                      const Text(
                        'As a CSR program of Cal4care’s Group, ITFS is driven by the belief that everyone, regardless of their background or circumstances, should have access to the necessary skills and knowledge to thrive in today’s digital world. Through our initiatives, we aim to empower individuals with the tools and resources to not only use technology confidently but also to pursue rewarding career opportunities in the IT industry.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'By bridging the gap between the tech-savvy and the technologically disadvantaged, ITFS is uplifting the less fortunate and creating new pathways for social and professional development. Through our efforts, we hope to create a more inclusive and equitable society where all individuals have the chance to succeed.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          color: Colors.blue.shade900,
                          child: GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse('https://www.cal4care.com')); 
                            },
                            child: const Image(
                              image: AssetImage('images/cal4care.png'),
                              height: 150,
                              fit: BoxFit.cover,
                            ), 
                          ),
                        ),
                      ), 
                      const SizedBox(height: 20),
                      Text(
                        'About Cal4care Group', 
                        textAlign: TextAlign.left, 
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade500,
                          decorationColor: Colors.orange.shade500,
                          decoration: TextDecoration.underline,
                        ) 
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Full-service VoIP Solutions',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ), 
                      const Text(
                        'In the fast-paced world of telecommunications, Cal4care stands out as a leading service provider with offices across Asia, the USA, and Europe. With a focus on developing cutting-edge communications platforms and manufacturing top-of-the-line telephone equipment, Cal4care has earned a reputation for excellence in the industry. As a licensed provider of telephone services, Cal4care is committed to delivering reliable and efficient communication solutions to businesses and individuals worldwide.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),  
                      const SizedBox(height: 20),
                      const Text(
                        'Attention: In today\'s digital age, effective communication is more important than ever. With Cal4care\'s state-of-the-art technology and vast global presence, we are able to meet the needs of a diverse range of clients, from small businesses to multinational corporations. Our commitment to innovation and customer satisfaction sets us apart from the competition, making Cal4care the preferred choice for all your telecommunications needs.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),  
                      const SizedBox(height: 20),
                      const Text(
                        'Interest: At Cal4care, we understand the importance of staying connected in a constantly evolving world. That\'s why we offer a wide range of services, including VoIP, cloud communications, and call center solutions, to help businesses streamline their operations and enhance their communication capabilities. Our expert team of professionals is dedicated to providing personalized service and support, ensuring that each client receives the attention and assistance they deserve.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ), 
                      const SizedBox(height: 20),
                      const Text(
                        'Desire: With offices located throughout Asia, the USA, and Europe, Cal4care is able to provide seamless communication solutions to clients around the globe. Whether you\'re looking to upgrade your current phone system or implement a new strategy for reaching customers, Cal4care has the expertise and resources to help you achieve your goals. Our advanced technology and industry-leading equipment make us the go-to choice for companies seeking reliable and efficient communication services.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Action: Ready to take your communication strategy to the next level? Contact Cal4care today to learn more about our services and how we can help you succeed in the digital age. With our comprehensive solutions and dedicated support team, we will work with you every step of the way to ensure your business communications are running smoothly and efficiently. Don\'t settle for subpar service – choose Cal4care for all your telecommunications needs.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse('www.cal4care.com'));
                            },
                            child: const Text(
                              'www.cal4care.com',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 7, 95, 218),
                              ),
                            ),
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ]
        )
      )
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
} 

class GroupEvent {
  final String id;
  final String groupType;
  final String groupName;
  final String eventTitle;
  final String time;
  final String eventDate;
  final String descriptionText;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupEvent({
    required this.id,
    required this.groupType,
    required this.groupName,
    required this.eventTitle,
    required this.date,
    required this.eventDate,
    required this.time,
    required this.descriptionText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return GroupEvent(
      id: json['id'],
      groupType: json['group_type'],
      groupName: json['group_name'],
      eventTitle: json['event_title'],
      date: DateTime.parse(json['date']),
      eventDate: json['date'],
      time: json['time'],
      descriptionText: json['description_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final String time;

  NotificationCard({
    required this.title,
    required this.message,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: $date',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Time: $time',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 