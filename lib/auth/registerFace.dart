import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';  
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sukio_member/utils/registerUser.dart';

class RegisterFace extends StatefulWidget {
  const RegisterFace({Key? key}) : super(key: key);

  @override
  _RegisterFaceState createState() => _RegisterFaceState();
}

class _RegisterFaceState extends State<RegisterFace> {
  late List<CameraDescription> _cameras;
  late CameraController? _controller;
  Timer? _timer;
  int _timerCountdown = 10;

  @override
  void initState() {
    super.initState(); 
    initializeCamera();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerCountdown > 0) {
          _timerCountdown--;
        } else {
          _timer?.cancel();
          captureImage();
        }
      });
    });
  }

  Future<void> initializeCamera() async { 
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('','No cameras found');
      }
      CameraDescription frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      _controller = CameraController(frontCamera, ResolutionPreset.max);
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Failed to initialize camera: $e');
    }
  }  

  Future<void> captureImage() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) { 
        XFile? imageFile = await _controller!.takePicture(); 
        if (imageFile != null) { 
          String id = await RegisterUserData.getRegisterId(); 
          var url = Uri.parse('https://ww2.selfiesmile.app/members/registerFaceId');
          var request = http.MultipartRequest('POST', url)
            ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
          request.fields['request_id'] = id; 
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);
          var responseData = json.decode(response.body);

          if (response.statusCode == 200) {
            print(responseData);
          }
        }
      } else {
        print('Camera controller is null or not initialized.');
      }
    } catch (e) {
      print('Error capturing or uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, 
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade900, 
      ),
      backgroundColor: Colors.blue.shade900,
      body: Column( 
        children: [ 
          Text('$_timerCountdown seconds', style: const TextStyle(color: Colors.white)),
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: ClipOval(
                    child: _controller != null ? CameraPreview(_controller!) : Container(),
                  ), 
                ),
              )
            )  
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 70),
            child: const Text(
              'Position your face in the circle until the enrollment is complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 70),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        captureImage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Capture",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                          const Visibility(
                            visible: false,
                            child: Row(
                              children: [
                                SizedBox(width: 10),
                                SizedBox(
                                  height: 17,
                                  width: 17,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white70),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
