import '/pages/login_page.dart';
import '/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: MediaQuery.of(context).size.height * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 30,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80), // Adjust the top space here
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.width * 0.6,
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Lottie.network('https://lottie.host/5cf76cdf-13d5-4eed-98fe-c143b22d73fe/U9bqqoM2Ez.json'),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Text(
                  "We’re evaluating your profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  'In order to make sure our community holds up a standard, we don’t allow any profiles to register.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  'Please wait for a while, Thank you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                FractionallySizedBox(
                  widthFactor: 0.5, // Adjust the width factor according to your preference
                  child: MaterialButton(
                    disabledColor: Colors.grey.shade300,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    color: Colors.orangeAccent,
                    height: MediaQuery.of(context).size.height * 0.05,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
