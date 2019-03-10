import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Models/payment_method.dart';
import 'package:gidi_ride_driver/Models/transaction.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TripEndedReview extends StatefulWidget {
  final DataSnapshot snapshot;

  TripEndedReview(this.snapshot);

  @override
  State<StatefulWidget> createState() => _TripEndedReview();
}

class _TripEndedReview extends State<TripEndedReview> {
  bool _inAsyncCall = false;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '';
  bool isPromoUsed = false;

  var paystackPublicKey;
  var paystackSecretKey;

  String total_trip_amount = '';
  DatabaseReference driverEarnRef;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseDatabase.instance
        .reference()
        .child('settings/keys')
        .once()
        .then((snapshot) {
      setState(() {
        paystackPublicKey = snapshot.value['paystackPublicKey'];
        paystackSecretKey = snapshot.value['paystackSecretKey'];
      });
      PaystackPlugin.initialize(
          publicKey: paystackPublicKey, secretKey: paystackSecretKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
      });
    });
    driverEarnRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/total_earned');
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(MyColors().primary_color),
      appBar: new AppBar(
        title: new Text('Ending Trip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25.0,
            )),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _inAsyncCall,
        opacity: 0.5,
        progressIndicator: CircularProgressIndicator(),
        color: Color(MyColors().button_text_color),
        child: new Container(
          height: MediaQuery.of(context).size.height,
          color: Color(MyColors().button_text_color), //primary_color
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              new Container(
                margin: EdgeInsets.only(top: 0.0),
                color: Color(MyColors().button_text_color),
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: new Text(
                  (ride_details['card_trip']) ? 'CARD PAYMENT' : 'CASH PAYMENT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.0,
                      fontWeight: FontWeight.w500),
                )),
              ),
              new Container(
                margin: EdgeInsets.only(top: 0.0),
                color: Color(MyColors().button_text_color),
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: new Text(
                  calculateTotalPrice(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 40.0,
                      fontWeight: FontWeight.w500),
                )),
              ),
              new Container(
                margin: EdgeInsets.only(top: 0.0),
                padding: EdgeInsets.all(20.0),
                child: new Text(
                  (ride_details['card_trip'])
                      ? 'Payment will be deducted automatically'
                      : 'Collect cash payment from rider',
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                  alignment: Alignment.bottomCenter,
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(
                      top: (MediaQuery.of(context).size.height / 3)),
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 0.0, left: 0.0, right: 0.0, bottom: 20.0),
                    child: new RaisedButton(
                      child: new Text('FINISH RIDE',
                          style: new TextStyle(
                              fontSize: 18.0,
                              color: Color(MyColors().button_text_color))),
                      color: Color(MyColors().secondary_color),
                      disabledColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      ),
                      onPressed: _doneClicked,
                      padding: EdgeInsets.all(15.0),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doneClicked() async {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    FavoritePlaces fp =
        FavoritePlaces.fromJson(ride_details['current_location']);
    FavoritePlaces fp2 = FavoritePlaces.fromJson(ride_details['destination']);
    PaymentMethods pm = (ride_details['card_trip'])
        ? PaymentMethods.fromJson(ride_details['payment_method'])
        : null;
    GeneralPromotions gp = (ride_details['promo_used'])
        ? GeneralPromotions.fromJson(ride_details['promotions'])
        : null;
    Fares fares = Fares.fromJson(ride_details['fare']);
    setState(() {
      _inAsyncCall = true;
    });
    DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
        'users/${ride_details['rider_email'].toString().replaceAll('.', ',')}/trips');
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}');
    userRef
        .child('incoming/${ride_details['id'].toString()}/status')
        .update({
      'current_ride_status': 'review driver',
      'trip_total_price': '₦$total_trip_amount'
    }).then((comp) {
      driverRef.child('accepted_trip').remove().then((comp) {
        DateTime dt = DateTime.now();
        String key = '${dt.day},${(dt.month)},${dt.year}';
        driverRef.child('trips/$key').push().set({
          'id': '${widget.snapshot.value['id'].toString()}',
          'status': '${widget.snapshot.value['status'].toString()}',
          'current_index':
              '${widget.snapshot.value['current_index'].toString()}',
          'current_location_reached':
              '${widget.snapshot.value['current_location_reached'].toString()}',
          'ride_started': '${widget.snapshot.value['ride_started'].toString()}',
          'ride_ended': '${widget.snapshot.value['ride_ended'].toString()}',
          'scheduled_reached': '${widget.snapshot.value['scheduled_reached']}',
          'trip_details': {
            'id': ride_details['id'].toString(),
            'current_location': fp.toJSON(),
            'destination': fp2.toJSON(),
            'trip_distance': ride_details['trip_distance'],
            'trip_duration': ride_details['trip_duration'],
            'payment_method':
                (ride_details['card_trip']) ? pm.toJSON() : 'cash',
            'vehicle_type': ride_details['vehicle_type'],
            'promotion': (gp != null) ? gp.toJSON() : 'no_promo',
            'card_trip': (ride_details['card_trip']) ? true : false,
            'promo_used': (gp != null) ? true : false,
            'scheduled_date': ride_details['scheduled_date'].toString(),
            'status': 'incoming',
            'created_date': ride_details['created_date'].toString(),
            'price_range': ride_details['price_range'].toString(),
            'trip_total_price': '₦$total_trip_amount',
            'fare': fares.toJSON(),
            'assigned_driver': _email,
            'rider_email': ride_details['rider_email'].toString(),
            'rider_name': ride_details['rider_name'].toString(),
            'rider_number': ride_details['rider_number'].toString(),
            'rider_msgId': ride_details['rider_msgId'].toString()
          }
        }).then((comp) {
          if (ride_details['card_trip']) {
            deductMoneyFromUser();
          } else {
            saveToTransactions("CASH_TRIP", true);
          }
        }); //debit and if promo and total earn
      });
    });
  }

  Future<void> saveToTransactions(String ref, bool success) async {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    PaymentMethods pm = (ride_details['card_trip'])
        ? PaymentMethods.fromJson(ride_details['payment_method'])
        : null;
    String id = ride_details['id'].toString();
    DatabaseReference transRef =
        FirebaseDatabase.instance.reference().child('transactions/$id');
    GidiTransaction transaction = GidiTransaction(
        id,
        total_trip_amount,
        ref,
        new DateTime.now().toString(),
        (ride_details['card_trip']) ? '${pm.payment_code}' : 'CASH',
        (ride_details['card_trip']) ? 'CARD' : 'CASH',
        _email,
        ride_details['rider_email'].toString(),
        success);
    transRef.set(transaction.toJSON()).then((c) {
      if (!success) {
        DatabaseReference userRef3 = FirebaseDatabase.instance.reference().child(
            'users/${ride_details['rider_email'].toString().replaceAll('.', ',')}/payments/${pm.payment_code}');
        userRef3.update({'available': false});
      }
      updateTotalEarned();
      if (isPromoUsed) {
        _promoUsed();
      } else {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().showToast('Thank you for choosing GidiRide', false);
        Route route = MaterialPageRoute(builder: (context) => UserHomePage());
        Navigator.pushReplacement(context, route);
      }
    });
  }

  void updateTotalEarned() {
    driverEarnRef.once().then((snap) {
      double initial_amount = 0;
      if (snap.value != null) {
        initial_amount = double.parse(snap.value.toString());
      }
      double update_amount = initial_amount + double.parse(total_trip_amount);
      driverEarnRef.set(update_amount);
    });
  }

  void _promoUsed() {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    GeneralPromotions gp = (ride_details['promo_used'])
        ? GeneralPromotions.fromJson(ride_details['promotions'])
        : null;
    if (gp != null) {
      //check user end if user uses promotion
      int number_of_rides_used = int.parse(gp.number_of_rides_used);
      String promo_code = gp.promo_code;
      DatabaseReference userRef2 = FirebaseDatabase.instance.reference().child(
          'users/${ride_details['rider_email'].toString().replaceAll('.', ',')}/promotions/$promo_code');
      if (number_of_rides_used == 1) {
        userRef2.remove();
      }
      if (number_of_rides_used > 1) {
        userRef2
            .update({'number_of_rides_used': '${(number_of_rides_used - 1)}'});
      }
    }

    setState(() {
      _inAsyncCall = false;
    });
    new Utils().showToast('Thank you for choosing GidiRide', false);
    Route route = MaterialPageRoute(builder: (context) => UserHomePage());
    Navigator.pushReplacement(context, route);
  }

  void deductMoneyFromUser() {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    PaymentMethods pm = PaymentMethods.fromJson(ride_details['payment_method']);
    http.post('https://api.paystack.co/transaction/charge_authorization',
        headers: {
          'Authorization': 'Bearer $paystackSecretKey'
        },
        body: {
          'authorization_code': pm.payment_code,
          'email': ride_details['rider_email'].toString(),
          'amount': '${total_trip_amount}00'
        }).then((c) {
      Map<String, dynamic> res = json.decode(c.body);
      bool status = res['status'];
      Map<String, dynamic> data = res['data'];
      String data_status = data['status'];
      String ref = data['reference'];
      if (status && data_status == 'success') {
        saveToTransactions(ref, true);
      } else {
        saveToTransactions(ref, false);
      }
    });
  }

  String calculateTotalPrice() {
    Map<dynamic, dynamic> ride_details = widget.snapshot.value['trip_details'];
    Fares fares = Fares.fromJson(ride_details['fare']);
    DateTime arrived_time = DateTime.parse(
        widget.snapshot.value['current_location_reached'].toString());
    DateTime start_time =
        DateTime.parse(widget.snapshot.value['ride_started'].toString());
    DateTime end_time =
        DateTime.parse(widget.snapshot.value['ride_ended'].toString());

    double wait_time =
        double.parse('${start_time.difference(arrived_time).inMinutes}');
    double trip_time =
        double.parse('${end_time.difference(start_time).inMinutes}');
    double trip_distance =
        double.parse(ride_details['trip_distance'].toString().split(' ')[0]);

    double total_distance = trip_distance * double.parse(fares.per_distance);
    double total_duration = trip_time * double.parse(fares.per_duration);
    double total_wait = wait_time * double.parse(fares.wait_time_fee);
    double total_start = double.parse(fares.start_fare);
    double over_all_total =
        total_distance + total_duration + total_wait + total_start;

    if (ride_details['promo_used']) {
      setState(() {
        isPromoUsed = true;
      });
      GeneralPromotions gp =
          GeneralPromotions.fromJson(ride_details['promotion']);
      String discount_type = gp.discount_type;
      if (discount_type == 'amount') {
        double amount_discount = double.parse(gp.discount_value);
        over_all_total = over_all_total - amount_discount;
        if (over_all_total < 0) {
          over_all_total = 0;
        }
      }
      if (discount_type == 'percent') {
        double percent_discount = double.parse(gp.discount_value);
        double max_value = double.parse(gp.maximum_value);
        double percent_off =
            ((over_all_total * percent_discount) / 100).ceilToDouble();
        if (percent_off > max_value) {
          over_all_total = over_all_total - max_value;
        } else {
          over_all_total = over_all_total - percent_off;
        }
      }
    }
    total_trip_amount = '${over_all_total.ceil()}';
    return '₦${over_all_total.roundToDouble()}';
  }
}
