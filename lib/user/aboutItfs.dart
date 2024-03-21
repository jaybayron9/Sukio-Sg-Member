import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutItfs extends StatelessWidget {
  const AboutItfs({ Key? key }) : super(key: key);

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
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      alignment: Alignment.center,  
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse('https://www.itfs.org.sg')); 
                        },
                        child: const Image(
                          image: AssetImage('images/logoitfs.png'),
                          height: 65,  
                          fit: BoxFit.cover,
                        ), 
                      ),
                    ),  
                    const SizedBox(height: 10),
                    Text(
                      'About ITFS', 
                      textAlign: TextAlign.left, 
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade500,
                        decorationColor: Colors.orange.shade500,
                        decoration: TextDecoration.underline,
                      ) 
                    ), 
                    const SizedBox(height: 5),
                    const Text(
                      'Information Technology Foundation Singapore (ITFS) is a unique and pioneering organization in Singapore, dedicated to addressing the digital divide within our society. As the first technology foundation of its kind in the country, ITFS is committed to providing essential technology education and hands-on training to individuals who have been less fortunate in receiving such opportunities in the past.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ), 
                    const SizedBox(height: 20),
                    const Text(
                      'As a CSR program of Cal4care’s Group, ITFS is driven by the belief that everyone, regardless of their background or circumstances, should have access to the necessary skills and knowledge to thrive in today’s digital world. Through our initiatives, we aim to empower individuals with the tools and resources to not only use technology confidently but also to pursue rewarding career opportunities in the IT industry.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'By bridging the gap between the tech-savvy and the technologically disadvantaged, ITFS is uplifting the less fortunate and creating new pathways for social and professional development. Through our efforts, we hope to create a more inclusive and equitable society where all individuals have the chance to succeed.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        color: Colors.blue.shade900,
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse('https://www.cal4care.com')); 
                          },
                          child: const Image(
                            image: AssetImage('images/cal4care.png'),
                            height: 150,
                            fit: BoxFit.cover,
                          ), 
                        ),
                      ),
                    ), 
                    const SizedBox(height: 20),
                    Text(
                      'About Cal4care Group', 
                      textAlign: TextAlign.left, 
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade500,
                        decorationColor: Colors.orange.shade500,
                        decoration: TextDecoration.underline,
                      ) 
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Full-service VoIP Solutions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ), 
                    const Text(
                      'In the fast-paced world of telecommunications, Cal4care stands out as a leading service provider with offices across Asia, the USA, and Europe. With a focus on developing cutting-edge communications platforms and manufacturing top-of-the-line telephone equipment, Cal4care has earned a reputation for excellence in the industry. As a licensed provider of telephone services, Cal4care is committed to delivering reliable and efficient communication solutions to businesses and individuals worldwide.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),  
                    const SizedBox(height: 20),
                    const Text(
                      'Attention: In today\'s digital age, effective communication is more important than ever. With Cal4care\'s state-of-the-art technology and vast global presence, we are able to meet the needs of a diverse range of clients, from small businesses to multinational corporations. Our commitment to innovation and customer satisfaction sets us apart from the competition, making Cal4care the preferred choice for all your telecommunications needs.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),  
                    const SizedBox(height: 20),
                    const Text(
                      'Interest: At Cal4care, we understand the importance of staying connected in a constantly evolving world. That\'s why we offer a wide range of services, including VoIP, cloud communications, and call center solutions, to help businesses streamline their operations and enhance their communication capabilities. Our expert team of professionals is dedicated to providing personalized service and support, ensuring that each client receives the attention and assistance they deserve.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ), 
                    const SizedBox(height: 20),
                    const Text(
                      'Desire: With offices located throughout Asia, the USA, and Europe, Cal4care is able to provide seamless communication solutions to clients around the globe. Whether you\'re looking to upgrade your current phone system or implement a new strategy for reaching customers, Cal4care has the expertise and resources to help you achieve your goals. Our advanced technology and industry-leading equipment make us the go-to choice for companies seeking reliable and efficient communication services.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Action: Ready to take your communication strategy to the next level? Contact Cal4care today to learn more about our services and how we can help you succeed in the digital age. With our comprehensive solutions and dedicated support team, we will work with you every step of the way to ensure your business communications are running smoothly and efficiently. Don\'t settle for subpar service – choose Cal4care for all your telecommunications needs.',
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
                            launchUrl(Uri.parse('www.cal4care.com'));
                          },
                          child: const Text(
                            'www.cal4care.com',
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
          )
        ]
      )
    );
  }
}