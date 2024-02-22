// import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '/pages/login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/checkCookie.dart';

class Event {
  final String title;
  final DateTime date;

  Event(this.title, this.date);
}


class DashboardPage extends StatefulWidget {
  final String? memberId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;
  final String? role;
  final String? qrCode;
  final String? group;

  const DashboardPage({Key? key, this.memberId, this.firstName, this.lastName, this.email, this.countryCode, this.phoneNumber, this.role, this.qrCode, this.group}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> { 
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<GroupEvent> events = []; 
  List<GroupEvent> filteredEvents = [];

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

      List<GroupEvent> groupEventsList =
          data.map((event) => GroupEvent.fromJson(event)).toList();

      return groupEventsList;
    } else {
      throw Exception('Failed to load group events');
    }
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

    fetchGroupEvents(widget.memberId.toString(), widget.group.toString()).then((result) {
      setState(() {
        events = result;
      });
    });
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
              title: const Text('Calendar'),
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
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
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
            )
          ],
        ),
      ),
      // Group Calendar
      Column(
        children: [
          TableCalendar(
            calendarFormat: _calendarFormat,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                // Filter events for the selected day
                filteredEvents = events
                    .where((event) => isSameDay(event.date, selectedDay))
                    .toList();
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
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
                    return ListTile(
                      title: Text(event.eventTitle),
                      subtitle: Text('Date: ${event.date.toLocal()}'),
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
              message: 'You have a meeting at the office.',
              date: '2024-02-28',
              time: '10:30 AM',
            ), 
          ],
        ),  
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

class GroupEvent {
  final String id;
  final String groupType;
  final String groupName;
  final String eventTitle;
  final DateTime date;
  final String time;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupEvent({
    required this.id,
    required this.groupType,
    required this.groupName,
    required this.eventTitle,
    required this.date,
    required this.time,
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
      time: json['time'],
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