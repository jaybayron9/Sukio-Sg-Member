import 'package:shared_preferences/shared_preferences.dart';

class SetUser {
  String? authId;
  String? membershipId;
  String? firstName;
  String? lastName;
  String? email;
  String? countryCode;
  String? phoneNumber;
  String? role;
  String? qr;
  String? group;
  String? profilePicture;

  SetUser(
    this.authId,
    this.membershipId,
    this.firstName,
    this.lastName,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.role,
    this.qr,
    this.group,
    this.profilePicture
  );

  setUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('authId', authId.toString());
    prefs.setString('membershipId', membershipId.toString());
    prefs.setString('firstName', firstName.toString());
    prefs.setString('lastName', lastName.toString());
    prefs.setString('email', email.toString());
    prefs.setString('countryCode', countryCode.toString());
    prefs.setString('phoneNumber', phoneNumber.toString());
    prefs.setString('role', role.toString());
    prefs.setString('qr', qr.toString());
    prefs.setString('group', group.toString());
    prefs.setString('profilePicture', profilePicture.toString());
  }  
}


class GetUser {
  static Future<Map<String, String?>> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'authId': prefs.getString('authId'),
      'membershipId': prefs.getString('membershipId'),
      'firstName': prefs.getString('firstName'),
      'lastName': prefs.getString('lastName'),
      'email': prefs.getString('email'),
      'countryCode': prefs.getString('countryCode'),
      'phoneNumber': prefs.getString('phoneNumber'),
      'role': prefs.getString('role'),
      'qr': prefs.getString('qr'),
      'group': prefs.getString('group'), 
      'profilePicture': prefs.getString('profilePicture')
    };
  }
}

class RemoveUser {
  removeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('authId');
    prefs.remove('membershipId');
    prefs.remove('firstName');
    prefs.remove('lastName');
    prefs.remove('email');
    prefs.remove('countryCode');
    prefs.remove('phoneNumber');
    prefs.remove('role');
    prefs.remove('qr');
    prefs.remove('group');
    prefs.remove('profilePicture');
  }
}