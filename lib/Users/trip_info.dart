import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/payment_method.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:zendesk/zendesk.dart';

class TripInfo extends StatefulWidget {
  final dynamic snapshot;

  TripInfo(this.snapshot);

  @override
  State<StatefulWidget> createState() => _TripInfo();
}

const api_key =
    "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI"; // "AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig";
const ZendeskApiKey = '6F888hSdWpJ789mZlJnOZ2rgpuHaTUgP';

class _TripInfo extends State<TripInfo> {
  String driver_image = '', driver_name = '';
  final Zendesk zendesk = Zendesk();

  Future<void> initZendesk() async {
    zendesk.init(ZendeskApiKey).then((r) {
      print('init finished');
    }).catchError((e) {
      print('failed with error $e');
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  Map<dynamic, dynamic> cts;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cts = widget.snapshot['trip_details'];
    initZendesk();
  }

  @override
  Widget build(BuildContext context) {
    //getDriverInfo();
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(MyColors().primary_color),
      appBar: new AppBar(
        title: new Text('Trip Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25.0,
            )),
        leading: new IconButton(
            icon: Icon(Icons.keyboard_arrow_left),
            onPressed: () {
              Navigator.pop(context, null);
            }),
      ),
      body: new Container(
        margin: EdgeInsets.only(top: 5.0),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            new Container(
                color: Color(MyColors().primary_color),
                child: new ListTile(
                  leading: Icon(
                    Icons.my_location,
                    color: Colors.green,
                  ),
                  title: Text(
                    getLocation('start'),
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                )),
            new Container(
              height: 1.0,
            ),
            new Container(
                color: Color(MyColors().primary_color),
                child: new ListTile(
                  leading: Icon(
                    Icons.directions,
                    color: Colors.red,
                  ),
                  title: Text(
                    getLocation('end'),
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                )),
            new Image.network(
              buildMapStaticUrl(),
              height: 150.0,
              repeat: ImageRepeat.noRepeat,
            ),
            new Container(
              child: new ListTile(
                leading: CircleAvatar(
                  radius: 30.0,
                  child: Image.asset(
                    'user_dp.png',
                    height: 60.0,
                    width: 60.0,
                  ),
                ),
                title: new Text(
                  'Your trip with ${cts['rider_name'].toString()}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500),
                ),
                subtitle: new Text(
                  cts['scheduled_date'].toString(),
                  style: TextStyle(color: Colors.white, fontSize: 13.0),
                ),
              ),
            ),
            new Container(
              color: Color(MyColors().button_text_color),
              padding: EdgeInsets.all(20.0),
              child: new Text(
                'Payment',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
            new ListTile(
              leading: (cts['card_trip'])
                  ? Icon(
                      Icons.credit_card,
                      color: Color(MyColors().secondary_color),
                    )
                  : Icon(
                      Icons.monetization_on,
                      color: Color(MyColors().secondary_color),
                    ),
              title: Text(
                (cts['card_trip'])
                    ? '•••• ${getPaymentMethodNumber()}'
                    : 'Cash',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500),
              ),
              trailing: Text(
                cts['trip_total_price'],
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900),
              ),
            ),
            new Container(
              color: Color(MyColors().button_text_color),
              padding: EdgeInsets.all(20.0),
              child: new Text(
                'Have any issues?',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
            new ListTile(
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
              title: Text(
                'Start a conversation',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              onTap: () {
                zendesk.startChat().then((r) {
                  print('startChat finished');
                }).catchError((e) {
                  print('error $e');
                });
              },
            ),
            Divider(
              height: 1.0,
              color: Color(MyColors().secondary_color),
            )
          ],
        ),
      ),
    );
  }

  String getLocation(String type) {
    FavoritePlaces fp;
    if (type == 'start') {
      fp = FavoritePlaces.fromJson(cts['current_location']);
      return fp.loc_name;
    } else {
      fp = FavoritePlaces.fromJson(cts['destination']);
      return fp.loc_name;
    }
  }

  String getPaymentMethodNumber() {
    PaymentMethods pm = PaymentMethods.fromJson(cts['payment_method']);
    return pm.number;
  }

  String buildMapStaticUrl() {
    FavoritePlaces fp_start = FavoritePlaces.fromJson(cts['current_location']);
    FavoritePlaces fp_end = FavoritePlaces.fromJson(cts['destination']);
    return 'https://maps.googleapis.com/maps/api/staticmap?center=${fp_start.latitude},${fp_start.longitude}&zoom=15&size=${(MediaQuery.of(context).size.width - 40).toInt()}x150&markers=size:tiny%7Ccolor:green%7C${fp_start.latitude},${fp_start.longitude}&markers=size:tiny%7Ccolor:red%7C${fp_end.latitude},${fp_end.longitude}&key=$api_key';
  }

//  Future<void> getDriverInfo() async {
//    DatabaseReference driverRef = FirebaseDatabase.instance.reference().child(
//        'drivers/${widget.snapshot.value['assigned_driver'].toString().replaceAll('.', ',')}/signup');
//    await driverRef.once().then((snapshot) {
//      setState(() {
//        driver_image = snapshot.value[''];
//        driver_name = snapshot.value[''];
//      });
//    });
//  }
}
