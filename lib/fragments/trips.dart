import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Models/trip.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Users/trip_info.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
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
        .child('users/${_email.replaceAll('.', ',')}/trips');
    await _ref1.child('past').once().asStream().toList().then((val) {//.asStream().length.
      if (val != null) {
        setState(() {
          //Map map = val.value;
          _Fcount = val.length;
        });
      }else{
        setState(() {
          _Fcount = 0;
        });
      }
    });
    await _ref1.child('incoming').once().asStream().toList().then((val) {
      if (val != null) {
        setState(() {
          //Map map = val.value;
          _Scount = val.length;
        });
      }else{
        setState(() {
          _Scount = 0;
        });
      }
    });
//    _ref1.child('incoming').once().then((val) {
//      if (val.value == null) {
//        setState(() {
//          _Fcount = 0;
//          _Scount = 0;
//        });
//      } else {
//        int f = 0, s = 0;
//        for (var value in val.value.values) {
//          print('trip values are $value');
//          Map<String, dynamic> vv = json.decode(value);
//          String status = vv['status'];
//          if(status != null) {
//            if (status == 'past') {
//              f = f + 1;
//            } else if (status == 'incoming') {
//              s = s + 1;
//            }
//          }
//        }
//        setState(() {
//          _Fcount = f;
//          _Scount = s;
//        });
//      }
//    });
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
    return DefaultTabController(
      length: 2,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Your Trips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.0,
              )),
          leading: new IconButton(
              icon: Icon(Icons.keyboard_arrow_left),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserHomePage()));
              }),
          bottom: TabBar(tabs: [
            Tab(icon: Icon(Icons.backspace, color: Colors.white), text: 'Past'),
            Tab(
              icon: Icon(
                Icons.bookmark,
                color: Colors.white,
              ),
              text: 'Incoming',
            ),
          ]),
        ),
        body: TabBarView(children: [
          (_Fcount > 0) ? buildList('past') : emptyJob(),
          (_Scount > 0) ? buildList('incoming') : emptyJob(),
//          buildList('past'),
//          buildList('incoming'),
        ]),
      ),
    );
  }

  Widget buildList(String type) {
    if (type == 'past') {
      return new FirebaseAnimatedList(
          query: FirebaseDatabase.instance
              .reference()
              .child('users/${_email.replaceAll('.', ',')}/trips/past'),
          scrollDirection: Axis.vertical,
          itemBuilder: (context, snapshot, animation, index) {
            //String status = snapshot.value['status'].toString();
            FavoritePlaces fp =
                FavoritePlaces.fromJson(snapshot.value['current_location']);
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
                          new Text(snapshot.value['scheduled_date'].toString(), style: TextStyle(fontWeight: FontWeight.w200)),
                          new Text(snapshot.value['vehicle_type']
                              .toString()
                              .toUpperCase(), style: TextStyle(color: Color(MyColors().secondary_color))),
                        ],
                      ),
                      leading: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black,
                      ),
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TripInfo(snapshot)),
                        );
                      },
                    )),
                  ],
                ),
              ),
            );
          });
    } else {
      return new FirebaseAnimatedList(
          query: FirebaseDatabase.instance
              .reference()
              .child('users/${_email.replaceAll('.', ',')}/trips/incoming'),
          scrollDirection: Axis.vertical,
          itemBuilder: (context, snapshot, animation, index) {
            //String status = snapshot.value['status'].toString();
            //Map<String, dynamic> cl = snapshot.value['current_location'];
            //CurrentTrip ct = CurrentTrip.fromSnapshot(snapshot);
            FavoritePlaces fp =
                FavoritePlaces.fromJson(snapshot.value['current_location']);
            GeneralPromotions gp = (snapshot.value['promo_used'])
                ? GeneralPromotions.fromJson(snapshot.value['promotion'])
                : null;
            return new SizeTransition(
              sizeFactor: animation,
              child: new SizedBox(
                child: new Column(
                  children: <Widget>[
                    Container(
                      child: ListTile(
                        title: Text(fp.loc_name,
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: new Text(
                            snapshot.value['scheduled_date'].toString()),
                        trailing: IconButton(
                          icon: Icon(Icons.cancel),
                          color: Colors.red[500],
                          onPressed: () {
                            _deleteIncomingOrder(snapshot.key);
                          },
                        ),
                      ),
                      padding:
                          EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                    ),
                    Container(
                      child: ListTile(
                        title: Text(snapshot.value['price_range'].toString(),
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: new Text(snapshot.value['vehicle_type']
                            .toString()
                            .toUpperCase()),
                        trailing: new Column(
                          children: <Widget>[
                            Text(
                                (snapshot.value['card_trip']) ? 'Card' : 'Cash',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            new Text((snapshot.value['promo_used'])
                                ? (gp.discount_type == 'percent')
                                    ? '-${gp.discount_value}%'
                                    : '-₦${gp.discount_value}'
                                : '')
                          ],
                        ),
                      ),
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    ),
                    new Divider(
                      height: 1.0,
                      color: Color(MyColors().button_text_color),
                    ),
                  ],
                ),
              ),
            );
          });
    }
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
                await delRef.child('users/${_email.replaceAll('.', ',')}/trips/status').remove();
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
