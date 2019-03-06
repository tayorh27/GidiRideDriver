import 'dart:async';
import 'dart:convert';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Models/payment_method.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:map_view/map_view.dart';

class DriverPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DriverPage();
}

enum DialogType { request, arriving, driving }

const kGoogleApiKey = "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI";
const api_key = 'AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI';
places.GoogleMapsPlaces _places =
    places.GoogleMapsPlaces(apiKey: kGoogleApiKey);

class _DriverPage extends State<DriverPage> {
  String _email = '', _number = '', _name = '', _msg = '', _vehicle_type = '';
  DatabaseReference locationRef;

  DialogType dialogType = DialogType.request;

  Map<String, double> _startLocation;
  Map<String, double> _currentLocation;

  StreamSubscription<Map<String, double>> _locationSubscription;

  loc.Location _location = new loc.Location();
  bool _permission = false;
  String error;
  final dateFormat = DateFormat("EEEE, MMMM d, yyyy 'at' h:mma");
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isGeneralTripsLoaded = false;

//  PaymentMethods _method = null;
//  GeneralPromotions _general_promotion = null;
//  Prediction getPrediction = null;
//
//  FavoritePlaces current_location = null;
//  FavoritePlaces destination_location = null;
//
  GoogleMapController mapController;

  //Completer<GoogleMapController> _controller = Completer();
  //var _mapView = new MapView();
  String current_trip_id;

//  CurrentTrip currentTrip;
//  DriverDetails driverDetails;
//
//  bool isCarAvail = false;
//  bool isBikeAvail = false;
//  bool isCash = false,
//      isRefreshing = true,
//      isBottomSheet = false,
  bool _inAsyncCall = false, isDriverVerified = false;
  List<dynamic> _snapshots = new List();
  DataSnapshot currentTripSnapshot;
  bool driver_has_accepted = false,
      driver_going_to_pickup = false,
      driver_delivery_item = false;
  String button_title = 'Go to pickup';
  int button_index = 0;

//  String payment_type = '';
//  String promotion_type = '';
//  double request_progress = null;
//  String trip_distance = '0 km', trip_duration = '0 min';
//  int trip_calculation;
//  Fares car_fares = null;
//  Fares bike_fare = null;
//  bool isLoaded = false, isScheduled = false, isAlreadyBooked = false;
//  bool isButtonDisabled = false;
//  String errorLoaded = '';
//
//  String ride_option_type_id = '', _date_scheduled = '';
//  bool ride_option_selected_car = false;
//  bool ride_option_selected_bike = false;
//
//  String appBarTitle = 'Rider arrives in ';

  Future<void> _onMapCreated(GoogleMapController controller) async {
    setState(() {
      mapController = controller;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Screen.keepOn(true);
    //listenForDestinationEntered();
    initPlatformState();
    _locationSubscription =
        _location.onLocationChanged().listen((Map<String, double> result) {
      double lat = result["latitude"];
      double lng = result["longitude"];
      setState(() {
        if (mapController != null) {
          updateMapCamera(lat, lng);
        }
        _currentLocation = result;
      });
    });
  }

  void updateMapCamera(double lat, double lng) {
    mapController.clearMarkers();
    if (dialogType == DialogType.request) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 20.0,
        ),
      ));
      mapController.addMarker(MarkerOptions(
          position: LatLng(lat, lng),
          alpha: 1.0,
          draggable: false,
          icon: BitmapDescriptor.defaultMarker,
          infoWindowText: InfoWindowText('Your location', '')));
      getMapLocation(lat, lng);
    }
    if (dialogType == DialogType.arriving) {
      if (!_locationSubscription.isPaused) {
        _locationSubscription.pause();
      }
//      mapController.animateCamera(CameraUpdate.newCameraPosition(
//        CameraPosition(
//          bearing: 90.0,
//          target: LatLng(lat, lng),
//          tilt: 30.0,
//          zoom: 20.0,
//        ),
//      ));
//      mapController.addMarker(MarkerOptions(
//          position: LatLng(lat, lng),
//          alpha: 1.0,
//          draggable: false,
//          icon: BitmapDescriptor.fromAsset('map_car.png'),
//          infoWindowText:
//          InfoWindowText('Driver location', '${driverDetails.fullname}')));
    }
    if (dialogType == DialogType.driving) {
      if (!_locationSubscription.isPaused) {
        _locationSubscription.pause();
      }
//      mapController.addMarker(MarkerOptions(
//          position: LatLng(lat, lng),
//          alpha: 1.0,
//          draggable: false,
//          icon: BitmapDescriptor.defaultMarker,
//          infoWindowText: InfoWindowText(
//              'Your Destination', '${destination_location.loc_name}')));
    }
  }

  Future<void> getMapLocation(double lat, double lng) async {
    locationRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/location');
    locationRef.set({
      'location_name': 'not set',
      'location_address': 'not set',
      'latitude': '$lat',
      'longitude': '$lng'
    });
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$api_key';
    await http.get(url).then((res) async {
      //new Utils().neverSatisfied(context, 'msg', res.body);
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['results'][0];
        String place_id = result['place_id'];
        places.PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(place_id);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String _lat = detail.result.geometry.location.lat.toString();
        String _lng = detail.result.geometry.location.lng.toString();

        locationRef.update({
          'location_name': loc_name,
          'location_address': loc_address,
          'latitude': _lat,
          'longitude': _lng
        });
      }
    });
  }

  initPlatformState() async {
    Map<String, double> location;
    try {
      _permission = await _location.hasPermission();
      location = await _location.getLocation();
      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }
      location = null;
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //if (!mounted) return;
    setState(() {
      _startLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _msg = pref.getString('msgId');
        _vehicle_type = pref.getString('vehicle_type');
        isDriverVerified = pref.getBool('userVerified');
      });
    });
    if (!isGeneralTripsLoaded) {
      getGeneralTrips();
    }
    // TODO: implement build
    return Scaffold(
        body: ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            color: Color(MyColors().button_text_color),
            child: new Container(
                child: new Stack(
                    overflow: Overflow.clip,
                    fit: StackFit.passthrough,
                    children: <Widget>[
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: LatLng(0.0, 0.0)),
                    onMapCreated: _onMapCreated,
                    compassEnabled: false,
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    trackCameraPosition: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                  new Container(
                      margin:
                          EdgeInsets.only(top: 60.0, left: 13.0, right: 13.0),
                      child: new Column(
                        children: <Widget>[
                          (!driver_has_accepted)
                              ? (_snapshots.length > 0)
                                  ? buildSliderForTrips()
                                  : new Text('')
                              : new Text(''),
                          driverHasAcceptedATrip(),
                        ],
                      )),
                ]))));
  }

  Widget buildSliderForTrips() {
    return new SizedBox(
        height: 220.0,
        child: CarouselSlider(
          height: 220.0,
          autoPlay: false,
          enlargeCenterPage: true,
          items: carouselChildren(),
        ));
  }

  Widget driverHasAcceptedATrip() {
    return Container(
        color: Color(MyColors().primary_color),
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.bottomCenter,
        height: 250.0,
        margin:
            EdgeInsets.only(top: (MediaQuery.of(context).size.height - 250.0)),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new ListTile(
                leading: new Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        image: new DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage('user_dp.png')))),
              ),
              new Container(
                margin: EdgeInsets.only(left: 13.0, right: 13.0),
                child: Padding(
                  padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
                  child: new RaisedButton(
                    child: new Text(button_title,
                        style: new TextStyle(
                            fontSize: 18.0,
                            color: Color(MyColors().button_text_color))),
                    color: Color(MyColors().secondary_color),
                    disabledColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    ),
                    onPressed: () {
                      _performButtonOperation(button_index);
                    },
                    //buttonDisabled
                    padding: EdgeInsets.all(15.0),
                  ),
                ),
              ),
            ]));
  }

  void _performButtonOperation(int index) {}

  List<Widget> carouselChildren() {
    List<Widget> mWidgets = new List();
    _snapshots.forEach((snap) {
      FavoritePlaces fp = FavoritePlaces.fromJson(snap['current_location']);
      DateTime scheduled_date =
          DateTime.parse(snap['scheduled_date'].toString());
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
      mWidgets.add(Container(
        color: Color(MyColors().primary_color),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new ListTile(
              title: new Text(
                'Pickup location',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              subtitle: new Text(
                fp.loc_name,
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              leading: Icon(
                Icons.my_location,
                color: Colors.green,
              ),
            ),
            new ListTile(
              title: new Text(
                'Scheduled for',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              subtitle: new Text(
                '${months[scheduled_date.month]}.${scheduled_date.day}.${scheduled_date.year}',
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
              leading: Icon(
                Icons.date_range,
                color: Colors.white,
              ),
            ),
            new Container(
              margin: EdgeInsets.only(left: 13.0, right: 13.0),
              child: Padding(
                padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
                child: new RaisedButton(
                  child: new Text('Accept Trip',
                      style: new TextStyle(
                          fontSize: 18.0,
                          color: Color(MyColors().button_text_color))),
                  color: Color(MyColors().secondary_color),
                  disabledColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  ),
                  onPressed: () {
                    _acceptTrip(snap);
                  },
                  //buttonDisabled
                  padding: EdgeInsets.all(15.0),
                ),
              ),
            ),
          ],
        ),
      ));
    });
    return mWidgets;
  }

  void _acceptTrip(dynamic values) {
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to accept this trip'),
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
              child: new Text(
                'Continue',
                style: TextStyle(color: Color(MyColors().primary_color)),
              ),
              onPressed: () {
                _tripAcceptedByDriver(values);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _tripAcceptedByDriver(dynamic values) async {
    FavoritePlaces fp = FavoritePlaces.fromJson(values['current_location']);
    FavoritePlaces fp2 = FavoritePlaces.fromJson(values['destination']);
    PaymentMethods pm =
        (!values['card_trip']) ? PaymentMethods.fromJson(values['']) : null;
    GeneralPromotions gp = GeneralPromotions.fromJson(values['promotions']);
    Fares fares = Fares.fromJson(values['fare']);

    DatabaseReference genRef = FirebaseDatabase.instance
        .reference()
        .child('general_trips/${values['id'].toString()}');
    await genRef.update({'assigned_driver': _email}).whenComplete(() {
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
          'users/${values['rider_email'].toString().replaceAll('.', ',')}/trips');
      userRef
          .child('incoming/${values['id'].toString()}')
          .update({'assigned_driver': _email}).whenComplete(() {
        userRef.child('status').update(
            {'current_ride_status': 'driver accepted'}).whenComplete(() {
          DatabaseReference driverRef = FirebaseDatabase.instance
              .reference()
              .child('driver/${_email.replaceAll('.', ',')}/accepted_trip');
          driverRef.set({
            'id': '${values['id'].toString()}',
            'status': 'awaiting pickup',
            'trip_details': {
              'id': values['id'].toString(),
              'current_location': fp.toJSON(),
              'destination': fp2.toJSON(),
              'trip_distance': values['trip_distance'],
              'trip_duration': values['trip_duration'],
              'payment_method': (!values['card_trip']) ? pm.toJSON() : 'cash',
              'vehicle_type': values['vehicle_type'],
              'promotion': (gp != null) ? gp.toJSON() : 'no_promo',
              'card_trip': (!values['card_trip']) ? true : false,
              'promo_used': (gp != null) ? true : false,
              'scheduled_date': values['scheduled_date'].toString(),
              'status': 'incoming',
              'created_date': values['created_date'].toString(),
              'price_range': values['price_range'].toString(),
              'fare': fares.toJSON(),
              'assigned_driver': _email,
              'rider_email': values['rider_email'].toString(),
              'rider_name': values['rider_name'].toString(),
              'rider_number': values['rider_number'].toString(),
              'rider_msgId': values['rider_msgId'].toString()
            }
          }).whenComplete(() async {
            //send notification to user saying a driver has accepted your trip
            //also schedule the time
            new Utils().sendNotification(
                'GidiRide Booking Status',
                'Your trip has been accepted by one of our driver. Your ride will be attended to in due time.',
                values['rider_msgId']);
            DateTime future_date =
                DateTime.parse(values['scheduled_date'].toString());
            DateTime now_date = DateTime.now();
            int diff = future_date.difference(now_date).inMinutes;
            int helloAlarmID = 0;
            await AndroidAlarmManager.oneShot(
                Duration(minutes: diff), helloAlarmID, alertDriver);
            setState(() {
              driver_has_accepted = true;
            });
          });
        });
      });
    });
  }

  void alertDriver() {}

  Future<void> getGeneralTrips() async {
    DatabaseReference genRef =
        FirebaseDatabase.instance.reference().child('general_trips');
    genRef.onValue.listen((ls) {
      _snapshots.clear();
      //new Utils().neverSatisfied(context, 'msg', 'snapshot length = ${ls.asMap()[0].value['id'].toString()}');
      if (ls.snapshot != null) {
        Map<dynamic, dynamic> values = ls.snapshot.value;
        values.forEach((key, vals) {
          if (vals['vehicle_type'].toString().toLowerCase() ==
                  _vehicle_type.toLowerCase() &&
              vals['assigned_driver'].toString() == 'none') {
            setState(() {
              _snapshots.add(vals);
            });
          }
        });
      }
      setState(() {
        isGeneralTripsLoaded = true;
      });
    });
  }
}
