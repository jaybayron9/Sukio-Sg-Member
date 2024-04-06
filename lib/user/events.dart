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
      backgroundColor: Colors.amber.shade500,
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
                        children: [ 
                          button(Icons.add, "Add Event", context, () {
                            final formatter = DateFormat('d MMMM y');
                            String date = formatter.format(_selectedDay);
                            setState(() {
                              selectedBookDate = date;
                              bookingTitle.text = '';
                              bookingMessage.text = '';
                              currentTime = TimeOfDay.now();
                            }); 
                            showModal(context);
                          }),
                          const SizedBox(height: 100),
                          const Text(
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
                          button(Icons.add, "Add Event", context, () {
                            final formatter = DateFormat('d MMMM y');
                            String date = formatter.format(_selectedDay);
                            setState(() {
                              selectedBookDate = date;
                              bookingTitle.text = '';
                              bookingMessage.text = '';
                              currentTime = TimeOfDay.now();
                            }); 
                            showModal(context);
                          }),
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
                                          title: Row(
                                            children: [
                                              Text(event.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
                                              Visibility(
                                                visible: event.bookingStatus == 'Booked' || event.memberId != 'null',
                                                child: Container(
                                                  margin: const EdgeInsets.only(left: 10),
                                                  decoration: const BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                  child: const Icon(Icons.add, size: 15),
                                                )
                                              ),
                                            ],
                                          ),
                                          // title: Text(
                                          //   '${event.eventTitle} ${event.bookingStatus == 'Booked' ? '(+)' : ''}',
                                          //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                          // ),
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
                                      visible: event.memberId == user['authId'],
                                      child: Positioned(
                                        right: 0,
                                        top: 10,
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 20),
                                          height: 30,
                                          width: 30,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              AwesomeDialog(
                                                context: context,
                                                dialogType: DialogType.warning,
                                                animType: AnimType.topSlide,
                                                title: 'Booking Cancel',
                                                desc: 'Are you sure, you want to cancel the event?',
                                                dismissOnTouchOutside: false,
                                                btnOkOnPress: () async {
                                                  await http.post(
                                                    Uri.parse('https://ww2.selfiesmile.app/member/cancel/event'),
                                                    body: {'event_id': event.id},
                                                  );
                                                },
                                                btnOkText: 'Yes',
                                                btnCancelOnPress: () {},
                                                btnCancelText: 'No'
                                              ).show();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,  
                                            ),
                                            child: Icon(Icons.delete, size: 18, color: Colors.red.shade500)
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

  showModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text("Book Event", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade900))),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                children: [
                  ToggleSwitch(
                    initialLabelIndex: 0,
                    minWidth: 100.0,
                    minHeight: 30,
                    activeBgColor: [Colors.blueAccent.shade200],
                    activeFgColor: Colors.white,
                    customTextStyles: const [TextStyle(color: Colors.white, fontSize: 15.0)],
                    multiLineText: true,
                    centerText: true,
                    totalSwitches: 2,
                    labels: ['All Group', user['group'].toString()],
                    onToggle: (index) {
                      groupType = index.toString();
                      print(groupType);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row( 
                    children: [
                      Text('Date : ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.grey.shade600),),
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          selectedBookDate, 
                          textAlign: TextAlign.start, 
                          style: TextStyle(
                            color: Colors.grey.shade800, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), 
                  Row(
                    children: [
                      Text('Time : ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.grey.shade600),),
                      TextButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: currentTime,
                          );
                          if (picked != null) {
                            String formattedHour = (picked.hourOfPeriod % 12).toString().padLeft(2, '0');
                            String formattedMinute = picked.minute.toString().padLeft(2, '0');
                            String period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                            String newTime = '$formattedHour:$formattedMinute $period';
                            setState(() {
                              selectedBookTime = newTime;
                            });
                          }
                        },
                        child: Text(
                          selectedBookTime.isNotEmpty ? selectedBookTime : 'Select Time',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ), 
                  TextFormField(
                    controller: bookingTitle,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 1.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: Colors.grey.shade700,
                    style: TextStyle(
                      color: Colors.grey.shade800, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 15), 
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    controller: bookingMessage,
                    decoration: InputDecoration(
                      hintText: 'Description',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 1.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: Colors.grey.shade600,
                    style: TextStyle(
                      color: Colors.grey.shade800, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 8), 
                ],
              ),
            );
          },
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
              foregroundColor: MaterialStateProperty.all<Color>(const Color(0xFF222222)),
            ),
            onPressed: () async {
              String type = groupType == '0' ? 'All Group' : 'Individual Group';
              Navigator.of(ctx).pop();
              setState(() { isSubmit = true; });
              final response = await http.post(
                Uri.parse('https://ww2.selfiesmile.app/member/book/event'),
                body: {
                  'group_type': type,
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
                    btnOkOnPress: () {},
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
              ],
            ),
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

  GroupEvent(
      {required this.id,
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
      required this.memberId});

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


















// child: ListView.builder(
//   itemCount: filteredEvents.length,
//   itemBuilder: (context, index) {
//     GroupEvent event = filteredEvents[index];
//     return Stack(
//       children: [
//         Container(
//           margin: const EdgeInsets.only(top: 25, bottom: 0, left: 30, right: 30),
//           decoration: BoxDecoration(color: event.eventColor, borderRadius: const BorderRadius.all(Radius.circular(10.0))),
//           child: ExpansionTile(
//             backgroundColor: event.eventColor,
//             title: Row(
//               children: [
//                 Expanded(
//                   child: Text(event.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//                 ),
//                 Visibility(
//                   visible: event.bookingStatus == 'Booked' || event.memberId != 'null',
//                   child: Container(
//                     margin: const EdgeInsets.only(left: 10),
//                     decoration: const BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.all(Radius.circular(5))),
//                     child: const Icon(Icons.add, size: 15),
//                   )
//                 ),
//               ],
//             ),
//             // title: Text(
//             //   '${event.eventTitle} ${event.bookingStatus == 'Booked' ? '(+)' : ''}',
//             //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
//             // ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: RichText(
//                         text: TextSpan(
//                           text: 'Date: ',
//                           style: const TextStyle(color: Colors.white),
//                           children: <TextSpan>[
//                             TextSpan(text: '${event.eventDate} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
//                             const TextSpan(text: 'Time: ', style: TextStyle(color: Colors.white)),
//                             TextSpan(text: '${event.time} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             collapsedIconColor: Colors.white,
//             iconColor: Colors.white,
//             textColor: Colors.white,
//             shape: const Border(),
//             children: <Widget>[
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         event.descriptionText,
//                         style: const TextStyle(color: Colors.white),
//                         textAlign: TextAlign.start,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Visibility(
//           visible: event.memberId == user['authId'],
//           child: Positioned(
//             right: 18,
//             top: 12,
//             child: SizedBox(
//               height: 30,
//               width: 30,
//               child: ElevatedButton( 
//                   onPressed: () async {
//                     AwesomeDialog(
//                       context: context,
//                       dialogType: DialogType.warning,
//                       animType: AnimType.topSlide,
//                       title: 'Booking Cancel',
//                       desc: 'Are you sure, you want to cancel the event?',
//                       dismissOnTouchOutside: false,
//                       btnOkOnPress: () async {
//                         await http.post(
//                           Uri.parse('https://ww2.selfiesmile.app/member/cancel/event'),
//                           body: {'event_id': event.id},
//                         );
//                       },
//                       btnOkText: 'Yes',
//                       btnCancelOnPress: () {},
//                     ).show();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.zero,
//                     shape: const CircleBorder(),
//                   ),
//                   child: Icon(Icons.close, color: Colors.red.shade300)),
//             ),
//           ),
//         ),
//       ],
//     );
//   },
// ),