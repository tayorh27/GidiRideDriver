import 'dart:async';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Users/user_login.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:map_view/map_view.dart';

void main() async{
  //MapView.setApiKey("AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig");
  await AndroidAlarmManager.initialize();
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'GidiRide Drivers',
      theme: new ThemeData(
          fontFamily: 'Lato',
          primarySwatch: MaterialColor(0xFF21252E, <int, Color>{
            50: const Color(0xFF21252E),
            100: const Color(0xFF21252E),
            200: const Color(0xFF21252E),
            300: const Color(0xFF21252E),
            400: const Color(0xFF21252E),
            500: const Color(0xFF21252E),
            600: const Color(0xFF21252E),
            700: const Color(0xFF21252E),
            800: const Color(0xFF21252E),
            900: const Color(0xFF21252E),
          }),
          accentColor: Color(MyColors().secondary_color)),
      debugShowCheckedModeBanner: false,
      home: new MyHomePage(title: 'GidiRide'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _MyHomePageState() {
    FirebaseAuth.instance.currentUser().then((user) {
      _timer = new Timer(new Duration(seconds: 3), () {
        _prefs.then((p){
          bool isLogged = (p.getBool('isLogged') == null) ? false : p.getBool('isLogged');
          if(isLogged && user != null){
            Route route = MaterialPageRoute(builder: (context) => UserHomePage());
            Navigator.pushReplacement(context, route);
          }else{
            Route route = MaterialPageRoute(builder: (context) => UserLogin());
            Navigator.pushReplacement(context, route);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if(_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
            child: new Container(
              child: Image.asset('sus_top.png'),
              alignment: Alignment.topRight,
            )),
        new Center(
            child: new Container(
              child: Image.asset('sus_middle.png'),
              alignment: Alignment.center,
            )),
        new Container(
          child: Image.asset('sus_bottom.png'),
          alignment: Alignment.bottomLeft,
        ),
      ],
    );
  }
}
