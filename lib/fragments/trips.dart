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
  int _Fcount = 0;

  var months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sept",
    "Oct",
    "Nov",
    "Dec"
  ];

  Future<void> performOp() async {
    DatabaseReference _ref1 = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/trips');
    await _ref1.once().then((val) {
      //.asStream().length.
      if (val.value != null) {
        setState(() {
          //Map map = val.value;
          _Fcount = 1;
        });
      } else {
        setState(() {
          _Fcount = 0;
        });
      }
    });
  }

  List<dynamic> _tripsSnapshot = new List();
  List<String> _tripsSnapshotKey = new List();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
      });
      loadTrips();
    });
    return MaterialApp(
      color: Color(MyColors().primary_color),
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
          })),
      debugShowCheckedModeBanner: false,
      home: buildTabs(),
    );
  }

  Widget buildTabs() {
    return DefaultTabController(
        length: _tripsSnapshot.length,
        initialIndex:
            (_tripsSnapshot.length > 0) ? (_tripsSnapshot.length - 1) : 0,
        child: new Scaffold(
          appBar: new AppBar(
            bottom: (_tripsSnapshot.length > 0)
                ? TabBar(
                    tabs: getHeaderTabs(),
                    indicatorColor: Color(MyColors().secondary_color),
                    labelColor: Colors.white,
                    isScrollable: true,
                    indicatorWeight: 2.0,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontSize: 20.0, letterSpacing: 1.5),
                    unselectedLabelStyle:
                        TextStyle(fontSize: 20.0, letterSpacing: 1.5),
                  )
                : null,
          ),
          body: (_tripsSnapshot.length > 0)
              ? TabBarView(
                  children: tabViews(),
                )
              : emptyTrip(),
        ));
  }

  List<Tab> getHeaderTabs() {
    List<Tab> mTabs = new List();
    var months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sept",
      "Oct",
      "Nov",
      "Dec"
    ];
    for (String key in _tripsSnapshotKey) {
      List<String> val = key.split(',');
      DateTime dateTime =
          DateTime(int.parse(val[2]), int.parse(val[1]), int.parse(val[0]));
      String title =
          '${months[(dateTime.month - 1)]} ${dateTime.day}, ${dateTime.year}';
      mTabs.add(new Tab(
        text: title,
      ));
    }
    return mTabs;
  }

  List<Widget> tabViews() {
    List<Widget> views = new List();
    for (int i = 0; i < _tripsSnapshot.length; i++) {
      Map<dynamic, dynamic> item = _tripsSnapshot[i];
      views.add(buildList(i, item));
    }
    return views;
  }

  Widget buildList(int key, Map<dynamic, dynamic> item) {
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: buildSubItems(key, item),
    );
//    return new FirebaseAnimatedList(
//        query: FirebaseDatabase.instance
//            .reference()
//            .child('drivers/${_email.replaceAll('.', ',')}/trips'),
//        scrollDirection: Axis.vertical,
//        itemBuilder: (context, snapshot, animation, index) {
//          Map<dynamic, dynamic> item = snapshot.value;
//        });
  }

  List<Widget> buildSubItems(int key, Map<dynamic, dynamic> items) {
    List<String> val = _tripsSnapshotKey[key].split(',');
    DateTime dateTime =
        DateTime(int.parse(val[2]), int.parse(val[1]), int.parse(val[0]));
    String title =
        '${months[(dateTime.month - 1)]} ${dateTime.day}, ${dateTime.year}';
    List<Widget> mWidget = new List();
    items.values.forEach((sub_items) {
      Map<dynamic, dynamic> cts = sub_items['trip_details'];
      FavoritePlaces fp = FavoritePlaces.fromJson(cts['current_location']);
      DateTime dt = DateTime.parse(sub_items['ride_ended'].toString());
      String date_ended = '${months[(dt.month - 1)]} ${dt.day}, ${dt.year}';
      mWidget.add(
        Container(
          margin: EdgeInsets.all(10.0),
          child: Text(
            title,
            style: TextStyle(
                color: Color(MyColors().primary_color),
                fontSize: 18.0,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
      mWidget.add(Padding(
        padding: EdgeInsets.all(20.0),
        child: new SizedBox(
          child: new Column(
            children: <Widget>[
              Container(
                  child: ListTile(
                title: Text(fp.loc_name,
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0)),
                subtitle: new Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Container(
                      height: 5.0,
                    ),
                    new Text(date_ended,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14.0)),
                    new Container(
                      height: 5.0,
                    ),
                    new Text(
                        (cts['status'].toString() == '0')
                            ? 'RIDE CANCELED'
                            : 'RIDE FINISHED',
                        style: TextStyle(
                            color: (cts['status'].toString() == '0')
                                ? Colors.red
                                : Color(MyColors().secondary_color))),
                    new Container(
                      height: 5.0,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TripInfo(sub_items)),
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
      ));
    });
    return mWidget;
  }

  void loadTrips() {
    DatabaseReference tripRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/trips');
    tripRef.onValue.listen((data) {
      _tripsSnapshot.clear();
      _tripsSnapshotKey.clear();
      if (data.snapshot.value != null) {
        Map<dynamic, dynamic> values = data.snapshot.value;
        values.forEach((key, vals) {
          setState(() {
            _tripsSnapshot.add(vals);
            _tripsSnapshotKey.add('$key');
          });
        });
      }
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

  Widget emptyTrip() {
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
