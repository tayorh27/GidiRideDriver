import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  String sms_USERNAME = "gidiride";

  String sms_PASSWORD = "Godisgood101";

  String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijg4OGNlODQ1Nzc4YjllMDA0MmNmM2ZmZGY4OTViNzAzNjY5NTBkMjdhZjRmOTQwYjA1ZWE0MzFiODU4MGU1OWJiNzZmYmMwZWRjOGU0MDA0In0.eyJhdWQiOiIxIiwianRpIjoiODg4Y2U4NDU3NzhiOWUwMDQyY2YzZmZkZjg5NWI3MDM2Njk1MGQyN2FmNGY5NDBiMDVlYTQzMWI4NTgwZTU5YmI3NmZiYzBlZGM4ZTQwMDQiLCJpYXQiOjE1NDUzNDYzNzUsIm5iZiI6MTU0NTM0NjM3NSwiZXhwIjoxNTc2ODgyMzc1LCJzdWIiOiIyMTQyNyIsInNjb3BlcyI6W119.P4WYKeKrltY4VtkZpa7JT4nlJlFcQ3SBjXtDywqw2r7PUQ6LplRFSqFTyKa8W1FKMKZ92ii5iWwRcOH9GUCM4m8RXFUjfR3NlCBQdOSWIFJCo-tfmtmLDJxKX0CcKUujgP3Acsh2R3gj43Aye74czV7r_lwWyLank9CnaKI0UIj8VaWm2Gr-ggxC_i8ya4dcMcAqH1ayJJeBND0eNW7JqI7NzUVeCwROir5km8HWlJAvdhxaOCwmyjT_SE49Gk-_bP00EeZ5s-AbpLLHLwqwb_5isD4jSBMdOVEikL58UB6rXH3Jock-ruwe7WWefRGwaAuSStCEKZbsXXSTWMqYAiXIBqArm62NnoKn2ZrDrx-aY5F75JBBSYvegOf3vicGmGbOCGyZ_tS56NXMyDKFpWXOTK45x77ge8p23U-DDqMekg00_5UOnw_mmeJEJ1ac4dAjyPz-syqUuZnIDBjgjbbkvBmyknvgJ-WfHRumie4UQ4OXGve-4eW6CHUJXR2_jXIpmH3SXT-KWP79DFE7bLgZXCV7uMgpXJf1_spaU4pgTQHivLQsCd44ko-q7iw3ciNuS9s5bGb8Wz2w6FH4HTkQ-K0rKT80SQqikbYqDGcJyEBFKE9RB8QYCkKLWx_zOLDwiBCBhl522OY9QsguoMkcTPhZxiZtkQKck6PtYH8';

  Future<bool> sendNotification(
      String title, String body, String msgId, String mobile) async {
    String sms_URL =
        'https://api.loftysms.com/simple/sendsms?username=$sms_USERNAME&password=$sms_PASSWORD&sender=GidiRide&sms_type=1&corporate=1&recipient=$mobile&message=$body'; //https://jusibe.com/smsapi/send_sms
    final response = await http.get(sms_URL, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      // on success do sth
      return true;
    } else {
      // on failure do sth
      return false;
    }

//    final postUrl = 'https://fcm.googleapis.com/fcm/send';
//
//    final data = {
//      "notification": {"body": "$body", "title": "$title"},
//      "priority": "high",
////      "data": {
////        "click_action": "FLUTTER_NOTIFICATION_CLICK",
////        "id": "1",
////        "status": "done"
////      },
//      "to": "$msgId"
//    };
//
//    final headers = {
//      'content-type': 'application/json',
//      'Authorization':
//          'key=AAAAb5Awy-A:APA91bFJ__L2edL1qeuLLZIcZivz72i_5IMfbCK7t2c8MuEdc0DJVoLVTQdBnjAkXXUAmMZagoXoFAGJJn92R6B_2_y0gSxmIVBgitVHARqeJfQW8gNFWVmNfFb1niNEEShzQvIru1On'
//    };
//
//    final response = await http.post(postUrl,
//        body: json.encode(data),
//        encoding: Encoding.getByName('utf-8'),
//        headers: headers);
//
//    print('SendNotification: ${response.body}');
  }

  Future<Null> neverSatisfied(
      BuildContext context, String _title, String _body) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(_body),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Null> displayFareInformation(
      BuildContext context, String _title, Fares snapshot) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new ListTile(
                  leading: new Text(
                    'Start fare',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.start_fare}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Wait time fee',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.wait_time_fee}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per distance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.per_distance}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per duration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '₦${snapshot.per_duration}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showToast(String text, bool isLong) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: isLong ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(MyColors().secondary_color),
        textColor: Color(MyColors()
            .button_text_color)); // backgroundColor: '#FFCA40', textColor: '#12161E');
  }

  void saveUserInfo(User user) {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((pref) {
      pref.setString('id', user.id);
      pref.setString('fullname', user.fullname);
      pref.setString('email', user.email);
      pref.setString('number', user.number);
      pref.setString('msgId', user.msgId);
      pref.setString('uid', user.uid);
      pref.setString('device_info', user.device_info);
      pref.setString('referralCode', user.referralCode);
      pref.setString('vehicle_type', user.vehicle_type);
      pref.setString('vehicle_model', user.vehicle_model);
      pref.setString('vehicle_plate_number', user.vehicle_plate_number);
      pref.setString('rating', user.rating);
      pref.setString('image', user.image);
      pref.setString('status', user.status);
      pref.setBool('userBlocked', user.userBlocked);
      pref.setBool('userVerified', user.userVerified);
    });
  }

  User getUser() {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    //User users;
    _prefs.then((pref) {
      return new User(
          pref.getString('id'),
          pref.getString('fullname'),
          pref.getString('email'),
          pref.getString('number'),
          pref.getString('msgId'),
          pref.getString('uid'),
          pref.getString('device_info'),
          pref.getString('referralCode'),
          pref.getString('vehicle_type'),
          pref.getString('vehicle_model'),
          pref.getString('vehicle_plate_number'),
          pref.getString('rating'),
          pref.getString('image'),
          pref.getString('status'),
          pref.getBool('userBlocked'),
          pref.getBool('userVerified'));
    });
    return null;
  }
}
