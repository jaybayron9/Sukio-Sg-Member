import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User { 
  static setUser(
    authId,
    membershipId,
    firstName,
    lastName,
    email,
    countryCode,
    phoneNumber,
    role,
    qr,
    group,
    profilePicture
  ) async {
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

  static removeUser() async {
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

  static enrollBiometricId(biometricId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('biometricId', biometricId.toString());
  }

  static getBiometricId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasBiometricId = prefs.containsKey('biometricId');
    if (hasBiometricId) {
      String id =  prefs.getString('biometricId').toString();
      return id;
    } else {
      var context;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        dismissOnTouchOutside: false,
        title: 'Error',
        desc: 'You have to log-in once to enabled face recognition',
        btnOkOnPress: () async { }
      );
    }
  }

  delBiometricId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('biometricId');
  }
}