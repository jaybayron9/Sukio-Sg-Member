import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  

class Events extends StatefulWidget {
  const Events({ Key? key }) : super(key: key);

  @override
  _EventsState createState() => _EventsState();
}

class _EventsState extends State<Events> {
  CalendarFormat _calendarFormat = CalendarFormat.month; 
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<GroupEvent> events = [];
  List<GroupEvent> filteredEvents = [];

  @override
  void initState() {
    super.initState();
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

  bool _hasEventsForDay(DateTime day) {
    return events.any((event) => isSameDay(event.date, day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      body: Column(
        children: [ 
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
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),  
                  decoration: BoxDecoration( 
                    color: Colors.blue.shade900,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30.0)),
                  ),
                  child: ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      GroupEvent event = filteredEvents[index];
                      return ExpansionTile(   
                        backgroundColor: Colors.blue.shade700,
                        title: Text(event.eventTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Date: ', style: TextStyle(color: Colors.white)),
                                Text('${event.eventDate} ',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 38,
        height: 38,
        child: Padding(
          padding: const EdgeInsets.all(0),
          // Today Event button
          child: FloatingActionButton(
            onPressed: () async {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                filteredEvents = events.where((event) => isSameDay(event.date, _selectedDay)).toList();
              });
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: const Icon(Icons.today_rounded),
          ),
        ),
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
