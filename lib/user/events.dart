// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/utils/user.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:toggle_switch/toggle_switch.dart';  

class Events extends StatefulWidget {
  const Events({ Key? key }) : super(key: key);

  @override
  _EventsState createState() => _EventsState();
}

class _EventsState extends State<Events> {
  Map<String, String?> user = {};
  CalendarFormat _calendarFormat = CalendarFormat.month; 
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<GroupEvent> events = [];
  List<GroupEvent> filteredEvents = [];
  bool isCreateBooking = false;
  bool isSubmit = false; 
  String selectedBookDate = '';
  String selectedBookTime = '00:00 AM';
  final TextEditingController bookingTitle = TextEditingController();
  final TextEditingController bookingMessage = TextEditingController();
  String groupType = ''; 
  TimeOfDay currentTime = TimeOfDay.now();
  String filterGroup = '';

  @override
  void initState() {
    super.initState();
    userData();
    websocket();
  }

  userData() async { 
    Map<String, String?> userData = await User.getUser(); 
    setState(() { user =  userData; });
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
        refreshEventsCalendar();
      }
    );
    await pusher.connect(); 
  } 

  refreshEventsCalendar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    fetchGroupEvents(prefs.getString('authId').toString(), prefs.getString('group').toString()).then((updatedEvents) {
      setState(() {
        events = updatedEvents; 
        filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
      });
    }); 
  }

  Future<List<GroupEvent>> fetchGroupEvents(String memberId, String group) async {
    final response = await http.post(
      Uri.parse('https://ww2.selfiesmile.app/member/group/event'),
      body: {'member_id': memberId, 'group': group},
    ); 
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body); 
      List<GroupEvent> groupEventsList = data.map((event) => GroupEvent.fromJson(event)).toList();
      return groupEventsList;
    } else {
      throw Exception('Failed to load group events');
    }
  }

  bool _hasEventsForDay(DateTime day) {
    return events.any((event) => isSameDay(event.date, day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: Colors.amber,
      body: Stack(
        children: [
          Column(
            children: [  
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ToggleSwitch(
                      initialLabelIndex: 0, 
                      minWidth: 150.0,
                      activeBgColor: [Colors.blue.shade900],
                      activeFgColor: Colors.white,
                      customTextStyles: const [
                        TextStyle(
                          color: Colors.white,
                          fontSize: 15.0
                        )
                      ],
                      multiLineText: true,
                      centerText: true,
                      totalSwitches: 2,
                      labels: ['All Group', 'My Group (${user['group']})'],
                      onToggle: (index) {
                        filterGroup = index.toString();
                      },
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
                  ],
                ),
              ), 
              // Events description
              Expanded(
                child: filteredEvents.isEmpty
                  ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),  
                    decoration: BoxDecoration( 
                      color: Colors.blue.shade900,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No event(s)',
                        style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  : Container(
                      decoration: BoxDecoration( 
                        color: Colors.blue.shade900,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
                      ),
                      child: ListView.builder(
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          GroupEvent event = filteredEvents[index];
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 25, bottom: 0, left: 30, right: 30),  
                                decoration: BoxDecoration(
                                  color: event.eventColor,
                                  borderRadius: const BorderRadius.all(Radius.circular(10.0))
                                ),
                                child: ExpansionTile(
                                  backgroundColor: event.eventColor, 
                                  title: Text(
                                    event.eventTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Date: ', style: TextStyle(color: Colors.white)),
                                          Text('${event.eventDate} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                          const Text('Time: ', style: TextStyle(color: Colors.white),),
                                          Text('${event.time} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                        ],
                                      ), 
                                    ],
                                  ), 
                                  collapsedIconColor: Colors.white,  
                                  iconColor: Colors.white,  
                                  textColor: Colors.white,   
                                  shape: const Border(),
                                  children: <Widget>[
                                    Container( 
                                      margin: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(event.descriptionText, style: const TextStyle(color: Colors.white))
                                    )
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: event.memberId == user['authId'],
                                child: Positioned(
                                  right: 18,
                                  top: 12,
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.topSlide,
                                          title: 'Cancel Event?', 
                                          dismissOnTouchOutside: false,
                                          btnOkOnPress: () async {
                                              final response = await http.post(
                                                Uri.parse('https://ww2.selfiesmile.app/member/cancel/event'),
                                                body: { 
                                                  'event_id': event.id
                                                },
                                              );
                                              if (response.statusCode == 200) {
                                                final Map<String, dynamic> res = json.decode(response.body);
                                                print(res);
                                                if (res['status'].toString() == 'true') {
                                                  AwesomeDialog(
                                                    context: context,
                                                    dialogType: DialogType.warning,
                                                    animType: AnimType.topSlide,
                                                    title: res['message'], 
                                                    dismissOnTouchOutside: false,
                                                    btnOkOnPress: (){}
                                                  ).show();
                                                }
                                              }
                                          },
                                          btnOkText: 'Yes',
                                          btnCancelOnPress: () {},
                                        ).show();
                                      }, 
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        shape: const CircleBorder(),
                                      ),
                                      child: const Icon(Icons.cancel, color: Colors.red)
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ); 
                        },
                      ),
                    ),
              ),
            ],
          ), 
          Positioned(
            bottom: 60,
            right: 3,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              onPressed: (){
                final formatter = DateFormat('d MMMM y');
                String date = formatter.format(_selectedDay); 
                setState(() { 
                  isCreateBooking = true; 
                  selectedBookDate = date;
                  bookingTitle.text = '';
                  bookingMessage.text = '';
                  currentTime = TimeOfDay.now();
                });
              },
              child: Icon(Icons.add, color: Colors.grey.shade800), 
            )
          ),  
          Positioned(
            bottom: 11,
            right: 3,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              onPressed: () async {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                  filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
                });
              },
              child: Icon(Icons.today_rounded, color: Colors.grey.shade800),
            )
          ),
          Visibility(
            visible: isCreateBooking,
            child: Stack(
              children: [
                Container(
                  color: Colors.white70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30), 
                            child: Container(
                              padding: const EdgeInsets.only(top: 30, bottom: 70, left: 30),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: const BorderRadius.all(Radius.circular(40)),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.today, color: Colors.white70, size: 25),
                                          const SizedBox(width: 14),
                                          Text(selectedBookDate, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.alarm_outlined, color: Colors.white70, size: 25),
                                          const SizedBox(width: 14),
                                          Text(selectedBookTime, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)), 
                                          SizedBox(
                                            child: TextButton( 
                                              onPressed: () async {
                                                final TimeOfDay? picked = await showTimePicker(
                                                  context: context,
                                                  initialTime: currentTime,
                                                );
                                                if (picked != null) {
                                                String formattedHour = (picked.hourOfPeriod % 12).toString().padLeft(2, '0');
                                                  String formattedMinute = picked.minute.toString().padLeft(2, '0');
                                                  String period = picked.period == DayPeriod.am ? 'AM' : 'PM';  
                                                  setState(() {
                                                    selectedBookTime = '$formattedHour:$formattedMinute $period';
                                                  });
                                                }
                                              }, 
                                              child: Icon(Icons.edit_sharp, color: Colors.green.shade200)
                                            ),
                                          ),
                                        ],
                                      ), 
                                      Container(
                                        margin: const EdgeInsets.only(left: 40),
                                        alignment: Alignment.topLeft,
                                        child: SizedBox(
                                          width: 200,
                                          child: TextFormField(
                                            controller: bookingTitle,
                                            decoration: const InputDecoration( 
                                              hintText: 'Title', 
                                              hintStyle: TextStyle(color: Colors.white54), 
                                              enabledBorder: UnderlineInputBorder( 
                                                borderSide: BorderSide(
                                                  color: Colors.white,
                                                  width: 1.0,
                                                ), 
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.white,
                                                  width: 1.0,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            cursorColor: Colors.white70,
                                            style: const TextStyle(color: Colors.white)
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        margin: const EdgeInsets.only(left: 40),
                                        alignment: Alignment.topLeft,
                                        child: SizedBox(
                                          width: 200,
                                          child: TextFormField(
                                            keyboardType: TextInputType.multiline,
                                            controller: bookingMessage,
                                            decoration: const InputDecoration(
                                              hintText: 'Message', 
                                              hintStyle: TextStyle(color: Colors.white54),
                                              enabledBorder: UnderlineInputBorder( 
                                                borderSide: BorderSide(
                                                  color: Colors.white,
                                                  width: 1.0,
                                                ), 
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.white,
                                                  width: 1.0,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            cursorColor: Colors.white70,
                                            style: const TextStyle(color: Colors.white)
                                          )
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container( 
                                        margin: const EdgeInsets.only(left: 5),
                                        alignment: Alignment.topLeft,
                                        child: Row(
                                          children: [
                                            const Text('To : ', style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800)),
                                            ToggleSwitch(
                                              initialLabelIndex: 0, 
                                              minWidth: 100.0,
                                              activeBgColor: [Colors.blueAccent.shade200],
                                              activeFgColor: Colors.white,
                                              customTextStyles: const [
                                                TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15.0
                                                )
                                              ],
                                              multiLineText: true,
                                              centerText: true,
                                              totalSwitches: 2,
                                              labels: const ['All Group', 'My Group'],
                                              onToggle: (index) {
                                                groupType = index.toString();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),  
                                  const Positioned(
                                    top: 105,
                                    left: 2,
                                    child: Icon(Icons.title_sharp, color: Colors.white70, size: 25), 
                                  ), 
                                  Positioned(
                                    top: 110,
                                    right: 50,
                                    child: Icon(Icons.edit_sharp, color: Colors.green.shade200)
                                  ),
                                  const Positioned(
                                    top: 160,
                                    left: 2,
                                    child: Icon(Icons.description_outlined, color: Colors.white70, size: 25), 
                                  ), 
                                  Positioned(
                                    top: 160,
                                    right: 50,
                                    child: Icon(Icons.edit_sharp, color: Colors.green.shade200)
                                  )
                                ],
                              )
                            ),
                          ),
                          Positioned(
                            top: 364,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 200,
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
                                    setState(() { isSubmit = true; });
                                    final response = await http.post(
                                      Uri.parse('https://ww2.selfiesmile.app/member/book/event'),
                                      body: {
                                        'group_type': groupType == '0' ? 'All Group' : 'Individual Group',
                                        'group_name': user['group'],
                                        'date': selectedBookDate,
                                        'time': selectedBookTime,
                                        'title': bookingTitle.text,
                                        'message': bookingMessage.text,
                                        'member_id': user['authId']
                                      },
                                    );
                                    if (response.statusCode == 200) {
                                      final Map<String, dynamic> res = json.decode(response.body);
                                      if (res['status'].toString() == 'true') {
                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.success,
                                          animType: AnimType.rightSlide,
                                          title: res['message'], 
                                          dismissOnTouchOutside: false,
                                          btnOkOnPress: () { 
                                            setState(() { isCreateBooking = false; });
                                          },
                                        ).show(); 
                                      }
                                    } 
                                    setState(() { isSubmit = false; });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.confirmation_num_outlined,
                                        color: Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SUBMIT',
                                        style: TextStyle(
                                          fontFamily: 'Circular',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      Visibility(
                                        visible: isSubmit,
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
                            ),
                          ), 
                          Positioned(
                            right: 8,
                            top: 15,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                                backgroundColor: Colors.red.shade500
                              ),
                              onPressed: (){
                                setState(() { isCreateBooking = false; });
                              }, 
                              child: const Icon(Icons.close, color: Colors.white)
                            )
                          ),  
                        ],
                      ),
                    ],
                  ),
                ), 
              ],
            )
          ),
        ],
      ),
    ); 
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
  final Color eventColor;
  final String bookingStatus;
  final String memberId;

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
    required this.eventColor,
    required this.bookingStatus,
    required this.memberId
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
      eventColor: convertHexToColor(json['event_color']),
      bookingStatus: json['booking_status'].toString(),
      memberId: json['member_id'].toString(),
    );
  }
}


Color convertHexToColor(String hexColor) { 
  if (hexColor.startsWith('#')) {
    hexColor = hexColor.substring(1);
  } 
  int parsedColor = int.parse(hexColor, radix: 16); 
  parsedColor = parsedColor + 0xFF000000; 
  return Color(parsedColor);
}