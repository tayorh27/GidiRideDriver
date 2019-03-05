import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
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
      pref.setBool('userBlocked', user.userBlocked);
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
          pref.getString('vehicle_model'),
          pref.getString('vehicle_plate_number'),
          pref.getString('rating'),
          pref.getString('image'),
          pref.getBool('userBlocked'),
          pref.getBool('userVerified'));
    });
    return null;
  }
}
