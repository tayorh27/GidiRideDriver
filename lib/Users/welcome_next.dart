import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';

class OpenWelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OpenWelcomePage();
}

class _OpenWelcomePage extends State<OpenWelcomePage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: new Stack(
      children: <Widget>[
        Positioned.fill(
            child: new Container(
          alignment: Alignment.center,
          color: Color(MyColors().primary_color),
          child: new Center(
              child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('welcome.png'),
              new Text('Having easy rides with real time updates',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ))
            ],
          )),
        )),
        new Container(
          alignment: Alignment.bottomRight,
          margin: EdgeInsets.all(30.0),
          child: new FloatingActionButton(
              backgroundColor: Color(MyColors().wrapper_color),
              foregroundColor: Color(MyColors().secondary_color),
              onPressed: () {
                Route route =
                    MaterialPageRoute(builder: (context) => UserHomePage());
                Navigator.pushReplacement(context, route);
              },
              child: Icon(Icons.arrow_forward, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)))),
        ),
      ],
    ));
  }
}
