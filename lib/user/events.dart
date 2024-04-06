// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'; 
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/utils/user.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:toggle_switch/toggle_switch.dart';

class Events extends StatefulWidget {
  const Events({Key? key}) : super(key: key);

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
  bool isSubmit = false;
  String selectedBookDate = '';
  String selectedBookTime = '00:00 AM';
  final TextEditingController bookingTitle = TextEditingController();
  final TextEditingController bookingMessage = TextEditingController();
  String groupType = '';
  TimeOfDay currentTime = TimeOfDay.now();
  int selectedGroupType = 0;
  String filterGroupType = 'All Group';
  bool isJoinedEvent = false;

  @override
  void initState() {
    super.initState();
    userData();
    websocket();
  }

  userData() async {
    Map<String, String?> userData = await User.getUser();
    setState(() {
      user = userData;
    });
  }

  websocket() async {
    final pusher = PusherChannelsFlutter.getInstance();
    await pusher.init(apiKey: '4d42882071c5e763a2af', cluster: 'ap1');
    await pusher.subscribe(
        channelName: "account-status",
        onEvent: (event) {
          refreshEventsCalendar();
        });
    await pusher.connect();
  }

  refreshEventsCalendar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    fetchGroupEvents(prefs.getString('authId').toString(), prefs.getString('group').toString(), filterGroupType).then((updatedEvents) {
      setState(() {
        events = updatedEvents;
        filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
      });
    });
  }

  Future<List<GroupEvent>> fetchGroupEvents(String memberId, String group, String groupType) async {
    final response = await http.post(
      Uri.parse('https://ww2.selfiesmile.app/member/group/event'),
      body: {'member_id': memberId, 'group': group, 'group_type': groupType},
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
      backgroundColor: Colors.grey.shade300,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToggleSwitch(
                          initialLabelIndex: selectedGroupType, 
                          minHeight: 28,
                          activeBgColor: [Colors.blue.shade900],
                          activeFgColor: Colors.white,
                          customTextStyles: const [TextStyle(color: Colors.white, fontSize: 10.0)],
                          multiLineText: true,
                          centerText: true,
                          totalSwitches: 2,
                          labels: ['All Group', user['group'].toString()],  
                          onToggle: (index) async {
                            setState(() {
                              selectedGroupType = index!.toInt();
                              if (selectedGroupType == 0) {
                                fetchGroupEvents(user['authId'].toString(), user['group'].toString(), 'All Group').then((updatedEvents) {
                                  setState(() {
                                    events = updatedEvents;
                                    filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
                                  });
                                });
                              } else if (selectedGroupType == 1) {
                                fetchGroupEvents(user['authId'].toString(), user['group'].toString(), 'My Group').then((updatedEvents) {
                                  setState(() {
                                    events = updatedEvents;
                                    filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
                                  });
                                });
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          visualDensity: VisualDensity.compact,
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
                          icon: Icon(Icons.today, color: Colors.blue.shade900, size: 28)
                        ), 
                      ],
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
                      child: ListView(
                        children: const [ 
                          SizedBox(height: 100),
                          Text(
                            'No event(s)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold),
                          ),  
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20), 
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) {
                                GroupEvent event = filteredEvents[index];
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 25),
                                      decoration: BoxDecoration(color: event.eventColor, borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: ExpansionTile( 
                                          backgroundColor: event.eventColor,
                                          collapsedIconColor: Colors.white,
                                          iconColor: Colors.white,
                                          textColor: Colors.white,
                                          shape: const Border(),
                                          title: Text(
                                            event.eventTitle,
                                            softWrap: true,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.white
                                            )
                                          ),  
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        text: 'Date: ',
                                                        style: const TextStyle(color: Colors.white),
                                                        children: <TextSpan>[
                                                          TextSpan(text: '${event.eventDate} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                                          const TextSpan(text: 'Time: ', style: TextStyle(color: Colors.white)),
                                                          TextSpan(text: '${event.time} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ), 
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                              decoration: const BoxDecoration(
                                                color: Colors.white70, 
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      event.descriptionText,
                                                      style: TextStyle(color: Colors.grey.shade800),
                                                      textAlign: TextAlign.start,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: true,
                                      child: Positioned(
                                        right: 0,
                                        top: 10,
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 20),
                                          height: 30,
                                          width: 30,
                                          child: IconButton(
                                            onPressed: () async {
                                              final response = await http.post(
                                                Uri.parse('https://ww2.selfiesmile.app/member/join/event'),
                                                body: { 
                                                  'member_id': user['authId'].toString(),
                                                  'event_id': event.id
                                                },
                                              );
                                              if (response.statusCode == 200) {
                                                final Map<String, dynamic> res = json.decode(response.body);
                                                if (res['status'].toString() == 'true') {
                                                  setState(() { isJoinedEvent = true; });
                                                  showModal(
                                                    context, 
                                                    event.eventTitle, 
                                                    event.eventDate, 
                                                    event.time, 
                                                    1, 
                                                    event.participantsNo, 
                                                    '19 min', 
                                                    user['authId'].toString(), 
                                                    event.id
                                                  );
                                                }
                                              }  
                                            },
                                            style: ElevatedButton.styleFrom( 
                                              padding: EdgeInsets.zero,
                                              backgroundColor: Colors.white,
                                              shadowColor: Colors.grey,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: const Icon(Icons.add, color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
              ),
            ],
          ), 
        ],
      ),
    );
  }

  Widget button(IconData iconButton, String text, BuildContext buildContext, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
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
          padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical: 10)),
          textStyle: MaterialStateProperty.all<TextStyle>(
            const TextStyle(
              fontFamily: 'Circular',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
        ),
        onPressed: onPressed,
        child: !isSubmit 
          ? Icon(
              iconButton,
              color: Colors.blue.shade800,
              weight: 200,
              size: 35,
            )
          : const SizedBox(
              height: 20,
              width: 20,
              child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70)),
            )
      ), 
    );
  }

  showModal(BuildContext context, eventTitle, date, time, memberJoin, participantsNo, duration, memberId, eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text("Event", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade900))),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 180,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column( 
                children: [
                  const SizedBox(height: 20),
                  Row( 
                    children: [
                      Text(
                        'Title: ', 
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade600, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                      Text(
                        eventTitle, 
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row( 
                    children: [
                      Text(
                        'Date: ', 
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade600, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        date, 
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row( 
                    children: [
                      Text(
                        'Time: ',
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade600, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        time,
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                    ]
                  ),
                  const SizedBox(height: 8),
                  Row( 
                    children: [
                      Text(
                        'Participants: ',
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade600, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        '$memberJoin/$participantsNo',
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                    ]
                  ),
                  const SizedBox(height: 8),
                  Row( 
                    children: [
                      Text(
                        'Duration: ',
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade600, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        duration,
                        textAlign: TextAlign.start, 
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        )
                      ), 
                    ]
                  ),
                ],
              ),
            );
          },
        ),
        actions: const <Widget>[
          // Center(
          //   child: 
          //     isJoinedEvent 
          //     ? ElevatedButton(
          //         style: ButtonStyle(
          //           backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
          //           foregroundColor: MaterialStateProperty.all<Color>(const Color(0xFF222222)),
          //         ),
          //         onPressed: () async {   
          //           final response = await http.post(
          //             Uri.parse('https://ww2.selfiesmile.app/member/join/event'),
          //             body: { 
          //               'member_id': memberId,
          //               'event_id': eventId
          //             },
          //           );
          //           if (response.statusCode == 200) {
          //             final Map<String, dynamic> res = json.decode(response.body);
          //             print(res);
          //             if (res['status'].toString() == 'true') { 
          //               Navigator.of(ctx).pop();
          //             }
          //           } 
          //         },
          //         child: Text(
          //           'JOIN EVENT',
          //           style: TextStyle(
          //             fontFamily: 'Circular',
          //             fontSize: 20,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.blue.shade800,
          //           ),
          //         ),
          //       )
          //     : ElevatedButton(
          //         style: ButtonStyle(
          //           backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
          //           foregroundColor: MaterialStateProperty.all<Color>(const Color(0xFF222222)),
          //         ),
          //         onPressed: () async {
          //           final response = await http.post(
          //             Uri.parse('https://ww2.selfiesmile.app/member/cancel/join/event'),
          //             body: { 
          //               'member_id': memberId,
          //               'event_id': eventId
          //             },
          //           );
          //           if (response.statusCode == 200) {
          //             final Map<String, dynamic> res = json.decode(response.body);
          //             print(res);
          //             if (res['status'].toString() == 'true') { 
          //               setState(() { isJoinedEvent = false; });
          //               Navigator.of(ctx).pop();
          //             }
          //           }
          //         },
          //         child: Text(
          //           'CANCEL JOIN',
          //           style: TextStyle(
          //             fontFamily: 'Circular',
          //             fontSize: 20,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.blue.shade800,
          //           ),
          //         ),
          //       )
          // ),
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
  final String participantsNo;

  GroupEvent({required this.id,
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
    required this.memberId,
    required this.participantsNo
  });

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return GroupEvent(
      id: json['id'],
      groupType: json['group_type'],
      groupName: json['group_name'].toString(),
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
      participantsNo: json['participants_no'].toString()
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