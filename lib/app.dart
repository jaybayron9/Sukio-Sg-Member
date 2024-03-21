// ignore_for_file: deprecated_member_use, unnecessary_constructor_name, avoid_print

import 'dart:async'; 
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/auth/login.dart';
import 'package:sukio_member/user/aboutItfs.dart';
import 'package:sukio_member/user/aboutUs.dart';
import 'package:sukio_member/user/dashboard/checkIn.dart';
import 'package:sukio_member/user/dashboard/checkOut.dart';
import 'package:http/http.dart' as http;
import 'package:sukio_member/user/ebooks.dart';
import 'dart:convert';  

import 'package:sukio_member/user/events.dart';  

class App extends StatefulWidget {
  const App({ Key? key }) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();  
  String _debugLabelString = ''; 
  List<Map<String, dynamic>> memberLogsData = []; 
  bool isCheckIn = false;
  String title = ''; 
  String firstName = '';
  String lastName = '';
  String membershipId = '';

  @override
  void initState() {
    super.initState();
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose); 
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(false); 
    OneSignal.initialize('df33667d-80b5-4062-9ccb-2325537fa02e');  
    OneSignal.Notifications.clearAll(); 
    OneSignal.User.pushSubscription.addObserver((state) async { 
      SharedPreferences prefs = await SharedPreferences.getInstance(); 
      await http.post(Uri.parse('https://ww2.selfiesmile.app/members/saveSubscriptionId'), body: { 
        'member_id': prefs.getString('authId').toString(), 'subscription_id': OneSignal.User.pushSubscription.id.toString()
      }); 
    }); 
    OneSignal.Notifications.addPermissionObserver((state) async { 
      SharedPreferences prefs = await SharedPreferences.getInstance(); 
      await http.post(Uri.parse('https://ww2.selfiesmile.app/members/saveSubscriptionId'), body: { 
        'member_id': prefs.getString('authId').toString(), 'subscription_id': OneSignal.User.pushSubscription.id.toString()
      }); 
    }); 
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event'); 
      setState(() {
        _debugLabelString = "Clicked notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    }); 
    OneSignal.Notifications.requestPermission(true);
    Timer.periodic(const Duration(seconds: 3), (timer) { 
      isNotCheckOut();
    });
    checkAccountStatus();
    isNotCheckOut();
    userInfo();
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
      }
    );
    await pusher.connect(); 
  }

  Future<void> checkAccountStatus() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/checkAccountStatus'), body: {
      'member_id': prefs.getString('authId').toString()
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
          title: 'Account Status asdf',
          desc: res['message'], 
          btnOkOnPress: () { 
            prefs.remove('authId');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const Login(),
                fullscreenDialog: true,
              ),
            ); 
          },
        ).show(); 
        prefs.remove('authId'); 
      }
    }
  } 

  Future<void> userInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName').toString();
      lastName = prefs.getString('lastName').toString();
      membershipId = prefs.getString('membershipId').toString(); 
    });  
  }  

  isNotCheckOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse('https://ww2.selfiesmile.app/members/isNotCheckOut'), body: {
      'member_id': prefs.getString('authId').toString()
    }); 
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body); 
      if (responseData['status'].toString() == 'true') { 
        setState(() { isCheckIn = true; });
      } else {
        setState(() { isCheckIn = false; });
      }
    }
  } 

  String _message = '';
  void _updateMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope.new(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          backgroundColor: Colors.blue.shade900, 
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          actions: [
            Container(
              height: 15,
              width: 15,
              margin: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: isCheckIn ? Colors.green : Colors.white70,
                borderRadius: const BorderRadius.all(
                  Radius.circular(20.0),
                ),
              ),
              child: Text(_message),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
              color: Colors.white,
            ), 
          ], 
        ),
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/checkIn':
                return MaterialPageRoute(builder: (_) => const CheckIn()); 
              case '/checkOut':
                return MaterialPageRoute(builder: (_) => const CheckOut()); 
              case '/events':
                  return MaterialPageRoute(builder: (_) => const Events());
              case '/ebooks':
                return MaterialPageRoute(builder: (_) => const Ebooks()); 
              case '/aboutUs':
                return MaterialPageRoute(builder: (_) => const AboutUs());
              case '/aboutItfs':
                return MaterialPageRoute(builder: (_) => const AboutItfs());
              case '/login':
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );              
              default:
                return MaterialPageRoute(builder: (_) => const CheckIn());
            }
          },
        ),
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
                                  '$firstName $lastName',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                Text(
                                  'ID: $membershipId',
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
                // selected: _selectedIndex == 0,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {  
                  _navigatorKey.currentState?.pushReplacementNamed('/checkIn');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Events'),
                trailing: const Icon(Icons.arrow_forward_ios),
                // selected: _selectedIndex == 1,
                onTap: () async {  
                  _navigatorKey.currentState?.pushReplacementNamed('/events');
                  Navigator.pop(context);
                },
              ), 
              ListTile(
                leading: const Icon(Icons.book),
                trailing: const Icon(Icons.arrow_forward_ios),
                title: const Text('eBooks'),
                // selected: _selectedIndex == 6,
                onTap: () async {  
                  _navigatorKey.currentState?.pushReplacementNamed('/ebooks');
                  Navigator.pop(context);
                },
              ),  
              ListTile(
                leading: const Icon(Icons.temple_buddhist),
                // selected: _selectedIndex == 7,
                title: const Text('About Us'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {  
                  _navigatorKey.currentState?.pushReplacementNamed('/aboutUs');
                  Navigator.pop(context);
                }
              ), 
              ListTile(
                leading: const Icon(Icons.diversity_1),
                // selected: _selectedIndex == 8,
                title: const Text('About ItFS'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  _navigatorKey.currentState?.pushReplacementNamed('/aboutItfs');
                  Navigator.pop(context);
                }
              ), 
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async { 
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  prefs.remove('authId');
                  Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => const Login(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  } 
}