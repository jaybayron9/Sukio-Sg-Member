import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            const Color.fromARGB(255, 62, 158, 236),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ListView(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                      image: AssetImage("images/sukioMahikari.png"),
                      fit: BoxFit.fill,
                    )),
                    margin: const EdgeInsets.only(bottom: 20),
                    alignment: Alignment.center,
                    child: const Image(
                      image: AssetImage('images/sukioMahikari.png'),
                      height: 200,
                      width: double.infinity,
                    ),
                  ),
                  const Text('About Sokio Mahikari',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 15),
                  const Text(
                    'Sukyo Mahikari is a spiritual organization that was founded in Japan in 1959 by Yoshikazu Okada. The name Sukyo Mahikari translates to "Universal Principles of Light and True Light" and is centered around the belief in the existence of a universal force called the "Divine Light." The main goal of Sukyo Mahikari is to help individuals to achieve spiritual growth and to contribute to the betterment of society through the practice of purification and the giving and receiving of light.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Central to the teachings of Sukyo Mahikari is the understanding of the importance of maintaining a spiritual balance in one\'s life. Members are encouraged to practice purification through the daily act of giving and receiving light as a means to cleanse their spiritual bodies and achieve a greater connection with the Divine Light. This practice is believed to promote physical and emotional well-being as well as spiritual enlightenment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Sukyo Mahikari has established centers all over the world where individuals can participate in regular light-giving and receiving sessions, study the teachings of the organization, and participate in community service activities.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Overall, Sukyo Mahikari provides a spiritual path for individuals seeking to find meaning and harmony in their lives through the practice of purification and the pursuit of spiritual enlightenment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse('http://sukyomahikari.asia'));
                        },
                        child: const Text(
                          'http://sukyomahikari.asia',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 7, 95, 218),
                          ),
                        ),
                      )
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