import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class ViewEbook extends StatefulWidget {
  final String file;
  ViewEbook({Key? key, required this.file}) : super(key: key);

  @override
  _ViewEbookState createState() => _ViewEbookState();
}

class _ViewEbookState extends State<ViewEbook> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      body: Stack(
        children: [
          const PDF().cachedFromUrl(
            'https://ww2.selfiesmile.app/ebooks-pdf/${widget.file.toString()}',
            placeholder: (progress) => Center(
              child: Text(
                '$progress %',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            errorWidget: (error) => Center(child: Text(error.toString())),
          ),
          IconButton(
            onPressed: (){
              Navigator.pop(context);
            }, 
            icon: Icon(Icons.arrow_back, size: 35, color: Colors.blue.shade900)
          )
        ],
      ),
    );
  }
}
