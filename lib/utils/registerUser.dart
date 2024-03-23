import 'package:shared_preferences/shared_preferences.dart';

class RegisterUserData {
  setRegisterInfo(
    firstName, 
    lastName, 
    email,
    countryCode,
    phoneNumber
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('firstName', firstName.toString());
    prefs.setString('lastName', lastName.toString());
    prefs.setString('email', email.toString());
    prefs.setString('countryCode', countryCode.toString());
    prefs.setString('phoneNumber', phoneNumber.toString()); 
  }

  setRegisterId(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('registeredId', id.toString());
  }

  static Future<String> getRegisterId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('registeredId').toString();
  }

  static Future<Map<String, String?>> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return { 
      'firstName': prefs.getString('firstName'),
      'lastName': prefs.getString('lastName'),
      'email': prefs.getString('email'),
      'countryCode': prefs.getString('countryCode'),
      'phoneNumber': prefs.getString('phoneNumber'), 
    };
  }

  deleteRegisterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('firstName');
    prefs.remove('lastName');
    prefs.remove('email');
    prefs.remove('countryCode');
    prefs.remove('phoneNumber');
  }
}