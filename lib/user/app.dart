import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukio_member/user/dashboard/checkIn.dart';

class App extends StatefulWidget {
  const App({ Key? key }) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();  
  String title = ''; 

  Future<void> deleteFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('admin_id');
  }

  Future navigateToPage(String route) async {
    _navigatorKey.currentState?.pushReplacementNamed(route);
    Navigator.pop(context);
  } 

  @override
  Widget build(BuildContext context) {
    return WillPopScope.new(
      onWillPop: () async {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog( 
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          backgroundColor: Colors.blue.shade900, 
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
              color: Colors.white,
            )
          ],
        ),
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const CheckIn()); 
              default:
                return MaterialPageRoute(builder: (_) => const CheckIn());
            }
          },
        ),
        drawer: Drawer(   
          child: Container(
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
            child: ListView(  
              children: [ 
                const SizedBox(height: 30),
                const Center(
                    child: Text(
                      'SUKIO MAHIKARI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ), 
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Home Page', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = ''; });
                    navigateToPage('/');
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.groups, color: Colors.white),
                  title: const Text('Member List', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap:() {
                    setState(() { title = 'Member List'; });
                    navigateToPage('/memberList');
                  }, 
                ),
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.white),
                  title: const Text('Visitor List', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = 'Visitor List'; });
                    navigateToPage('/visitorList');
                  } 
                ),
                ListTile(
                  leading: const Icon(Icons.temple_buddhist, color: Colors.white),
                  title: const Text('About Us', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = ''; });
                    navigateToPage('/aboutus');
                  } 
                ),
                ListTile(
                  leading: const Icon(Icons.diversity_1, color: Colors.white),
                  title: const Text('About ItFS', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = ''; });
                    navigateToPage('/aboutitfs');
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.white),
                  title: const Text('Users', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = 'Users'; });
                    navigateToPage('/user');
                  } 
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Exit QR', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    setState(() { title = ''; });
                    navigateToPage('/exitqr');
                  } 
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)), 
                  onTap: () {
                    deleteFromLocalStorage();
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
                  },
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}