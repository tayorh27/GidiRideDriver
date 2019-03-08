import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Users/trip_info.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTrips extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyTrips();
}

class _MyTrips extends State<MyTrips> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '';
  int _Fcount = 0, _Scount = 0;

  Future<void> performOp() async {
    DatabaseReference _ref1 = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/trips');
    await _ref1.once().asStream().toList().then((val) {
      //.asStream().length.
      if (val != null) {
        setState(() {
          //Map map = val.value;
          _Fcount = val.length;
        });
      } else {
        setState(() {
          _Fcount = 0;
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        //_name = pref.getString('fullname');
        _email = pref.getString('email');
      });
      performOp();
    });
    return new Scaffold(
      body: Container(
        child: (_Fcount > 0) ? buildList() : emptyJob(),
      ),
    );
  }

  Widget buildList() {
    return new FirebaseAnimatedList(
        query: FirebaseDatabase.instance
            .reference()
            .child('drivers/${_email.replaceAll('.', ',')}/trips'),
        scrollDirection: Axis.vertical,
        itemBuilder: (context, snapshot, animation, index) {
          //String status = snapshot.value['status'].toString();
          Map<dynamic, dynamic> cts = snapshot.value['trip_details'];
          FavoritePlaces fp = FavoritePlaces.fromJson(cts['current_location']);
          return new SizeTransition(
            sizeFactor: animation,
            child: new SizedBox(
              child: new Column(
                children: <Widget>[
                  Container(
                      child: ListTile(
                    title: Text(fp.loc_name,
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: new Column(
                      children: <Widget>[
                        new Text(cts['scheduled_date'].toString(),
                            style: TextStyle(fontWeight: FontWeight.w200)),
                        new Text('FINISHED',
                            style: TextStyle(
                                color: Color(MyColors().secondary_color))),
                      ],
                    ),
                    leading: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TripInfo(snapshot)),
                      );
                    },
                  )),
                  Divider(
                    height: 1.0,
                    color: Color(MyColors().button_text_color),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _deleteIncomingOrder(String id) {
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to delete this incoming trip?'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Continue'),
              onPressed: () async {
                new Utils().showToast('Please wait...', false);
                DatabaseReference delRef =
                    FirebaseDatabase.instance.reference();
                await delRef
                    .child('users/${_email.replaceAll('.', ',')}/trips/$id')
                    .remove();
                await delRef.child('general_trips/$id').remove();
                await delRef
                    .child('users/${_email.replaceAll('.', ',')}/trips/status')
                    .remove();
                new Utils().showToast('Deleted successfully', false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget emptyJob() {
    return new Container(
        child: new Center(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Image.asset(
            'header_logo.png',
          ),
          new Text(
            'You have no data yet.',
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(fontSize: 16.0),
          )
        ],
      ),
    ));
  }
}
