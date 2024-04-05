import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sukio_member/user/ebooks/viewEbook.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Ebooks extends StatefulWidget {
  const Ebooks({Key? key}) : super(key: key);

  @override
  _EbooksState createState() => _EbooksState();
}

class _EbooksState extends State<Ebooks> {
  late Stream<List<dynamic>> _booksStream;

  @override
  void initState() {
    super.initState();
    _booksStream = fetchBooks().asStream();
  }

  Future<List<dynamic>> fetchBooks() async {
    final response = await http.post(
        Uri.parse("https://ww2.selfiesmile.app/member/get/ebooks"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Widget eBook(title, img, pdf) {
    return TextButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
      onPressed: () {
        print(pdf);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEbook(file: pdf),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 188,
            height: 300,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.network(
              'https://ww2.selfiesmile.app/ebooks-cover/$img',
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 180,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              softWrap: true,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: () async {
          setState(() {
            _booksStream = fetchBooks().asStream();
          });
          return await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              const SizedBox(height: 20),
              StreamBuilder<List<dynamic>>(
                stream: _booksStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<dynamic> books = snapshot.data!;
                    return Wrap(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.start,
                      spacing: 15,
                      runSpacing: 25,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: books.map((book) {
                        return eBook(book['title'], book['book_cover'], book['file_name']);
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(top: 200),
                      child: const CircularProgressIndicator(color: Colors.blueAccent),
                    );
                  }
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
