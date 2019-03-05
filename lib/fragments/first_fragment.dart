import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:gidi_ride_driver/Models/driver.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Models/payment_method.dart';
import 'package:gidi_ride_driver/Models/trip.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Users/review_driver.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:gidi_ride_driver/fragments/payment.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screen/screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class MapFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MapFragment();
}

const kGoogleApiKey = "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI";
//"AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig"; //"AIzaSyB_2OfHqOnXS577kNUKckBB0yu49g8Rw40";
const api_key =
    "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI"; // "AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();
String _email = '', _number = '', _name = '', _msg = '';
String address_type = 'current';
bool isSavedPlace = false;

enum DialogType { request, arriving, driving }

class _MapFragment extends State<MapFragment> {
  DialogType dialogType = DialogType.request;

  Map<String, double> _startLocation;
  Map<String, double> _currentLocation;

  StreamSubscription<Map<String, double>> _locationSubscription;

  loc.Location _location = new loc.Location();
  bool _permission = false;
  String error;
  final dateFormat = DateFormat("EEEE, MMMM d, yyyy 'at' h:mma");
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  PaymentMethods _method = null;
  GeneralPromotions _general_promotion = null;
  Prediction getPrediction = null;

  FavoritePlaces current_location = null;
  FavoritePlaces destination_location = null;

  GoogleMapController mapController;
  String current_trip_id;
  CurrentTrip currentTrip;
  DriverDetails driverDetails;

  bool isCarAvail = false;
  bool isBikeAvail = false;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  bool isCash = false,
      isRefreshing = true,
      isBottomSheet = false,
      _inAsyncCall = false;
  String payment_type = '';
  String promotion_type = '';
  double request_progress = null;
  String trip_distance = '0 km', trip_duration = '0 min';
  int trip_calculation;
  Fares car_fares = null;
  Fares bike_fare = null;
  bool isLoaded = false, isScheduled = false, isAlreadyBooked = false;
  bool isButtonDisabled = false;
  String errorLoaded = '';

  String ride_option_type_id = '', _date_scheduled = '';
  bool ride_option_selected_car = false;
  bool ride_option_selected_bike = false;

  String appBarTitle = 'Rider arrives in ';

  @override
  void initState() {
    // TODO: implement initState
    Screen.keepOn(true);
    listenForDestinationEntered();
    getBookingFares();
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
    // Fired whenever a location is recorded
//    bg.BackgroundGeolocation.onLocation((bg.Location location) {
//      double lat = location.coords.latitude;
//      double lng = location.coords.longitude;
//      updateMapCamera(lat,lng);
//      //print('[location] - $location');
//    });
//    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
//    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
//      double lat = location.coords.latitude;
//      double lng = location.coords.longitude;
//      updateMapCamera(lat,lng);
//      //print('[motionchange] - $location');
//    });
//    // Fired whenever the state of location-services changes.  Always fired at boot
//    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
//      //print('[providerchange] - $event');
//    });
//    bg.BackgroundGeolocation.ready(bg.Config(
//        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
//        distanceFilter: 10.0,
//        stopOnTerminate: false,
//        startOnBoot: true,
//        debug: true,
//        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
//        reset: true
//    )).then((bg.State state) {
//      if (!state.enabled) {
//        bg.BackgroundGeolocation.start();
//      }
//    });
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

  Future<void> getBookingFares() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('settings');
    await ref.child('fees').child('booking_fee').child('car').once().then((val) {
      setState(() {
        car_fares = Fares.fromSnapshot(val);
      });
    });
    await ref.child('fees').child('booking_fee').child('bike').once().then((val) {
      setState(() {
        bike_fare = Fares.fromSnapshot(val);
      });
    });
    await ref.child('availability').once().then((val) {
      setState(() {
        isCarAvail = val.value['isCarAvailable'];
        isBikeAvail = val.value['isBikeAvailable'];
      });
    });
  }

  void updateMapCamera(double lat, double lng) {
    mapController.clearMarkers();
    if (dialogType == DialogType.request) {
      setState(() {
        isRefreshing = true;
        if (address_type != 'destination') address_type = 'current';
      });
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 25.0,
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
          icon: BitmapDescriptor.fromAsset('map_car.png'),
          infoWindowText:
              InfoWindowText('Driver location', '${driverDetails.fullname}')));
    }
    if (dialogType == DialogType.driving) {
      if (!_locationSubscription.isPaused) {
        _locationSubscription.pause();
      }
      mapController.addMarker(MarkerOptions(
          position: LatLng(lat, lng),
          alpha: 1.0,
          draggable: false,
          icon: BitmapDescriptor.defaultMarker,
          infoWindowText: InfoWindowText(
              'Your Destination', '${destination_location.loc_name}')));
    }
  }

  Future<void> getMapLocation(double lat, double lng) async {
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$api_key';
    http.get(url).then((res) async {
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      //new Utils().neverSatisfied(context, 'hello', res.body); /////////////////////////////////
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['results'][0];
        String place_id = result['place_id'];
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(place_id);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String _lat = detail.result.geometry.location.lat.toString();
        String _lng = detail.result.geometry.location.lng.toString();
        setState(() {
          if (address_type == 'current') {
            current_location =
                FavoritePlaces('', loc_name, loc_address, '$_lat', '$_lng', '');
          }
//          else {
//            destination_location =
//                FavoritePlaces('', loc_name, loc_address, '$_lat', '$_lng', '');
//          }
          isRefreshing = false;
        });
      } else {
        setState(() {
          isRefreshing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
//    if(_locationSubscription != null){
//      if(!_locationSubscription.isPaused){
//        _locationSubscription.resume();
//      }
//    }
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _msg = pref.getString('msgId');
        if (pref.getString('payment') != null) {
          payment_type = pref.getString('payment');
          if (pref.getString('payment') == 'cash') {
            isCash = true;
            payment_type = 'cash';
          }
        } else {
          isCash = true;
          payment_type = 'cash';
        }
        promotion_type = (pref.getString('promotion_type') != null)
            ? pref.getString('promotion_type')
            : '';
      });
    });
    loadPayment();
    loadPromotion(); //change payment method
    checkAlreadyBooked();
    // TODO: implement build
    return new Scaffold(
        appBar: (dialogType == DialogType.arriving ||
                dialogType == DialogType.driving)
            ? new AppBar(
                title: new Text(appBarTitle),
              )
            : null,
        //appBar: new AppBar(title: Text('Hello Map'),leading: new IconButton(icon: Icon(Icons.menu, color: Colors.white,), onPressed: (){}),),
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
                  onMapCreated: _onMapCreated,
                      compassEnabled: false,
                      mapType: MapType.normal,
                      myLocationEnabled: true,
                      trackCameraPosition: true,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                ),
                new Container(
                    margin: EdgeInsets.only(top: 60.0, left: 13.0, right: 13.0),
                    child: new Column(
                      children: <Widget>[
                        new Container(
                            color: Color(MyColors().primary_color),
                            child: new ListTile(
                              leading: (!isRefreshing)
                                  ? Icon(
                                      Icons.my_location,
                                      color: Colors.green,
                                    )
                                  : new Container(
                                      height: 18.0,
                                      width: 18.0,
                                      child: CircularProgressIndicator(
                                        value: null,
                                      ),
                                    ),
                              trailing: Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              ),
                              title: Text(
                                (current_location == null)
                                    ? 'Your current location'
                                    : current_location.loc_name,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16.0),
                              ),
                              onTap: (currentTrip == null)
                                  ? () {
                                      setState(() {
                                        address_type = 'current';
                                      });
                                      _buttonTapped();
                                    }
                                  : null,
                            )),
                        new Container(
                          height: 2.0,
                        ),
                        new Container(
                            color: Color(MyColors().primary_color),
                            child: new ListTile(
                              leading: Icon(
                                Icons.directions,
                                color: Colors.red,
                              ),
                              trailing: Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              ),
                              title: Text(
                                (destination_location == null)
                                    ? 'Enter Destination'
                                    : destination_location.loc_name,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16.0),
                              ),
                              onTap: (currentTrip == null)
                                  ? () {
                                      setState(() {
                                        address_type = 'destination';
                                      });
                                      _buttonTapped();
                                    }
                                  : null,
                            )),
                      ],
                    )),
                (isBottomSheet)
                    ? new Container(
                        margin: EdgeInsets.only(
                            top: (MediaQuery.of(context).size.height - 380)),
                        alignment: Alignment.bottomCenter,
                        height: 380.0,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: new Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            new LinearProgressIndicator(
                              value: request_progress,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(MyColors().secondary_color)),
                            ),
                            (isLoaded)
                                ? vehicleTypeOptions(
                                    'car',
                                    'gidicar.png',
                                    'GidiRide Car',
                                    '1-4',
                                    getPrice('car'),
                                    ride_option_selected_car,
                                    isCarAvail)
                                : new Text(''),
                            (isLoaded)
                                ? vehicleTypeOptions(
                                    'bike',
                                    'gidibike.png',
                                    'GidiRide Bike',
                                    '1',
                                    getPrice('bike'),
                                    ride_option_selected_bike,
                                    isBikeAvail)
                                : new Text(''),
                            new Container(
                              margin: EdgeInsets.only(
                                  left: 20.0, right: 20.0, top: 5.0),
                              child: Divider(
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                            new ListTile(
                                title: (!isCash)
                                    ? Text(
                                        '${(_method != null) ? '•••• ${_method.number}' : ''}')
                                    : new Text('Cash',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.0)),
                                onTap: () {
                                  _changePaymentMethod();
                                },
                                leading: (!isCash)
                                    ? new Icon(
                                        Icons.credit_card,
                                        color:
                                            Color(MyColors().secondary_color),
                                      )
                                    : new Icon(
                                        Icons.monetization_on,
                                        color:
                                            Color(MyColors().secondary_color),
                                      ),
                                trailing: new FlatButton.icon(
                                    onPressed: () {
                                      DatePicker.showDateTimePicker(context,
                                          showTitleActions: true,
                                          //min: DateTime.now(),
                                          onChanged: (date) {
                                        _date_scheduled = date.toString();
                                      }, onConfirm: (date) {
                                        _date_scheduled = date.toString();
                                        setState(() {
                                          isScheduled = true;
                                        });
                                      },
                                          currentTime: DateTime.now(),
                                          locale: LocaleType.en);
                                    },
                                    icon: Icon(
                                      (isScheduled)
                                          ? Icons.event_available
                                          : Icons.event,
                                      color: (isScheduled)
                                          ? Colors.green
                                          : Colors.black,
                                    ),
                                    label: new Text(
                                      'Schedule',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          color: (isScheduled)
                                              ? Colors.green
                                              : Colors.black),
                                    ))),
                            new Container(
                              margin: EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: 0.0, left: 0.0, right: 0.0),
                                child: new RaisedButton(
                                  child: new Text('Confirm Booking',
                                      style: new TextStyle(
                                          fontSize: 18.0,
                                          color: Color(
                                              MyColors().button_text_color))),
                                  color: Color(MyColors().secondary_color),
                                  disabledColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                  ),
                                  onPressed:
                                      (isLoaded) ? _confirmBooking : null,
                                  //buttonDisabled
                                  padding: EdgeInsets.all(15.0),
                                ),
                              ),
                            ),
                            new Container(
                              height: 5.0,
                            ),
                            new Container(
                              child: Center(
                                child: new FlatButton(
                                  onPressed: () {
                                    setState(() {
                                      isBottomSheet = false;
                                      destination_location = null;
                                    });
                                  },
                                  child: new Text('Cancel',
                                      style: new TextStyle(
                                          fontSize: 14.0,
                                          color: Color(
                                              MyColors().button_text_color))),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    : new Text(''),
                (currentTrip != null) ? dialogTypeAfterRequest() : new Text('')
              ],
            ))));
  }

  Widget vehicleTypeOptions(String id, String image, String title, String seats,
      String price_range, bool isSelected, bool isAvail) {
    return new Container(
      padding: EdgeInsets.all(0.0),
      margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      decoration: (isSelected)
          ? BoxDecoration(
              border: Border.all(
                  color: Color(MyColors().secondary_color),
                  width: 1.5,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10.0))
          : null,
      child: new ListTile(
        leading: new Image.asset(image, height: 64.0, width: 53.0),
        title: new Text(
          title,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: new Row(
          children: <Widget>[
            new Icon(
              Icons.person,
              size: 18.0,
            ),
            new Text(
              seats,
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: new Column(
          children: <Widget>[
            new Text(
              price_range,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isAvail) {
            new Utils().neverSatisfied(context, 'Error',
                'Sorry this option is not available at the moment. Try again later.');
            return;
          }
          setState(() {
            ride_option_type_id = id;
            if (id == 'car') {
              ride_option_selected_car = true;
              ride_option_selected_bike = false;
            } else {
              ride_option_selected_bike = true;
              ride_option_selected_car = false;
            }
          });
        },
        onLongPress: (){
          _infoPressed(id);
        },
      ),
    );
  }

  void _infoPressed(String type) {
    if(type == 'car'){
      new Utils().displayFareInformation(context, 'Car Fares', car_fares);
    }else {
      new Utils().displayFareInformation(context, 'Bike Fares', bike_fare);
    }
  }

  Widget dialogTypeAfterRequest() {
    if (dialogType == DialogType.arriving || dialogType == DialogType.driving) {
      return new Container(
        margin:
            EdgeInsets.only(top: (MediaQuery.of(context).size.height - 250)),
        alignment: Alignment.bottomCenter,
        height: 250.0,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: new Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new ListTile(
              leading: new Column(
                children: <Widget>[
                  new Container(
                      width: 100.0,
                      height: 100.0,
                      decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          image: new DecorationImage(
                            fit: BoxFit.cover,
                            image: (driverDetails != null)
                                ? new NetworkImage(driverDetails.image)
                                : AssetImage('user_dp.png'),
                          ))),
                  new Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5.0))),
                    color: Colors.grey,
                    width: 50.0,
                    height: 25.0,
                    child: new Row(
                      children: <Widget>[
                        new Icon(
                          Icons.star,
                          size: 18.0,
                        ),
                        new Text(
                          driverDetails.rating,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              isThreeLine: true,
              title: new Text(
                driverDetails.fullname,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Text(driverDetails.vehicle_model,
                      style: TextStyle(
                        fontSize: 10.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      )),
                  new Text(driverDetails.vehicle_plate_number,
                      style: TextStyle(
                        fontSize: 10.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ))
                ],
              ),
              trailing: new IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () {
                    _launchURL(driverDetails.number);
                  }),
            ),
            new Container(
              height: 10.0,
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            new Container(
              color: Colors.white,
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new FlatButton.icon(
                        onPressed: null,
                        icon: (currentTrip.card_trip)
                            ? new Icon(
                                Icons.credit_card,
                                color: Color(MyColors().secondary_color),
                              )
                            : new Icon(
                                Icons.monetization_on,
                                color: Color(MyColors().secondary_color),
                              ),
                        label: (currentTrip.card_trip)
                            ? Text(
                                '${(currentTrip.payment_method != null) ? currentTrip.payment_method.number : ''}',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w900),
                              )
                            : new Text('Cash',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w900)),
                      )
                    ],
                  ),
                  new Text(
                    currentTrip.price_range,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  (currentTrip.promo_used)
                      ? new Text(
                          (currentTrip.promotion.discount_type == 'percent')
                              ? '-${currentTrip.promotion.discount_value}%'
                              : '-₦${currentTrip.promotion.discount_value} Promo',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : new Text(''),
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return new Text('');
    }
  }

  Future<Null> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String getPrice(String id) {
      double dist = double.parse(trip_distance.split(' ')[0]);
      double dur = double.parse(trip_distance.split(' ')[0]);
      if (id == 'car') {
        double total = (dist * double.parse(car_fares.per_distance)) +
            (dur * double.parse(car_fares.per_duration)) +
            double.parse(car_fares.start_fare);
        double total_range = total + 400;
        return '₦${total.ceil()} - ₦${total_range.ceil()}';
      } else {
        double total = (dist * double.parse(bike_fare.per_distance)) +
            (dur * double.parse(bike_fare.per_duration)) +
            double.parse(bike_fare.start_fare);
        double total_range = total + 200;
        return '₦${total.ceil()} - ₦${total_range.ceil()}';
      }
  }

  _confirmBooking() async {
    if (isAlreadyBooked) {
      new Utils().neverSatisfied(context, 'Error',
          'You have booked a ride that has not yet been completed.');
      return;
    }
    if (!isScheduled) {
      new Utils().neverSatisfied(context, 'Error', 'Please set a date.');
      return;
    }
    if (_method != null) {
      if (!_method.available) {
        new Utils().neverSatisfied(
            context, 'Error', 'Payment method not available for use');
        return;
      }
    }
    if (ride_option_type_id == ''){
      new Utils().neverSatisfied(
          context, 'Error', 'Please select a ride option.');
      return;
    }
    setState(() {
      request_progress = null;
      isButtonDisabled = true;
      _inAsyncCall = true;
    });
    DatabaseReference tripRef = FirebaseDatabase.instance.reference();
    String id = tripRef.push().key;
    await tripRef
        .child('users/${_email.replaceAll('.', ',')}/trips/incoming')
        .child(id)
        .set({
      'id': id,
      'current_location': current_location.toJSON(),
      'destination': destination_location.toJSON(),
      'trip_distance': trip_distance,
      'trip_duration': trip_duration,
      'payment_method': (!isCash) ? _method.toJSON() : 'cash',
      'vehicle_type': ride_option_type_id,
      'promotion': (_general_promotion != null)
          ? _general_promotion.toJSON()
          : 'no_promo',
      'card_trip': (!isCash) ? true : false,
      'promo_used': (_general_promotion != null) ? true : false,
      'scheduled_date': _date_scheduled,
      'status': 'incoming',
      'created_date': DateTime.now().toString(),
      'price_range': getPrice(ride_option_type_id),
      'fare':
          (ride_option_selected_car) ? car_fares.toJSON() : bike_fare.toJSON(),
      'assigned_driver': 'none'
    }).whenComplete(() {
      tripRef.child('general_trips').child(id).set({
        'id': id,
        'current_location': current_location.toJSON(),
        'destination': destination_location.toJSON(),
        'trip_distance': trip_distance,
        'trip_duration': trip_duration,
        'payment_method': (!isCash) ? _method.toJSON() : 'cash',
        'vehicle_type': ride_option_type_id,
        'promotion': (_general_promotion != null)
            ? _general_promotion.toJSON()
            : 'no_promo',
        'card_trip': (!isCash) ? true : false,
        'promo_used': (_general_promotion != null) ? true : false,
        'scheduled_date': _date_scheduled,
        'status': 'incoming',
        'created_date': DateTime.now().toString(),
        'price_range': getPrice(ride_option_type_id),
        'fare': (ride_option_selected_car)
            ? car_fares.toJSON()
            : bike_fare.toJSON(),
        'assigned_driver': 'none',
        'rider_email': _email,
        'rider_name': _name,
        'rider_number': _number,
        'rider_msgId': _msg
      }).whenComplete(() {
        _afterBooking(id);
      });
    });
  }

  _afterBooking(String id) async {
    DatabaseReference afterTripRef = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips/status');
    await afterTripRef.set({
      'current_ride_id': id,
      'current_ride_status': 'awaiting response'
    }).whenComplete(() {
      String subj = "A ride has been booked";
      String message = "A user of email address";
      var url = "http://gidiride.ng/emailsending/bookings.php?subject=$subj&";
      http.get(url).then((response) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().showToast('Ride successfully booked.', true);
        Route route = MaterialPageRoute(builder: (context) => UserHomePage());
        Navigator.pushReplacement(context, route);

        //send notification to all drivers
        //
      });
    });
  }

  _buttonTapped() async {
    _locationSubscription.pause();
    final results = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomSearchScaffold()),
    );
    if (results != null) {
      setState(() {
        if (address_type == 'current') {
          current_location = results;
          updateMapCamera(double.parse(current_location.latitude),
              double.parse(current_location.longitude));
        } else {
          destination_location = results;
        }
      });
      if (destination_location != null && current_location != null) {
        displayBottomDialog();
      }
    }
  }

  _changePaymentMethod() async {
    final results = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Payment(true)),
    );
    if (results != null) {
      setState(() {
        payment_type = results;
        if (payment_type != 'cash') {
          loadPayment();
        }
      });
      //new Utils().neverSatisfied(context, 'error', 'payment type = $payment_type');
      //displayBottomDialog();
    }
  }

  Future<void> getPlaceAutoComplete(String type) async {
    try {
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.fullscreen,
          // Mode.fullscreen
          onError: onError);
      setState(() {
        getPrediction = p;
        address_type = type;
      });
    } catch (e) {}
  }

  void onError(PlacesAutocompleteResponse response) {
    print('error ====== ${response.errorMessage}');
  }

  Future<void> loadPayment() async {
    if (payment_type != 'cash') {
      DatabaseReference payRef2 = FirebaseDatabase.instance
          .reference()
          .child('users/${_email.replaceAll('.', ',')}/payments/$payment_type');
      await payRef2.once().then((snapshot) {
        if (snapshot != null) {
          setState(() {
            _method = PaymentMethods.fromSnapShot(snapshot);
            isCash = false;
          });
        }
      });
    }
  }

  Future<void> loadPromotion() async {
    if (promotion_type.isNotEmpty) {
      DatabaseReference promoRef2 = FirebaseDatabase.instance.reference().child(
          'users/${_email.replaceAll('.', ',')}/promotions/$promotion_type');
      await promoRef2.once().then((snapshot) {
        if (snapshot != null) {
          setState(() {
            _general_promotion = GeneralPromotions.fromSnapShot(snapshot);
          });
        }
      });
    }
  }

  Future<void> checkAlreadyBooked() async {
    DatabaseReference statusRef = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips/status');
    statusRef.once().then((snapshot) {
      if (snapshot.value != null) {
        String val = snapshot.value['current_ride_status'];
        setState(() {
          current_trip_id = snapshot.value['current_ride_id'];
          isAlreadyBooked = true;
          if (val == 'driver assigned') {
            dialogType = DialogType.arriving;
          } else if (val == 'en-route') {
            dialogType = DialogType.driving;
            appBarTitle = 'Driving to destination';
          }
        });
        if (val == 'review driver') {
          getCurrentTripDetails(current_trip_id, true);
        } else if (val != 'awaiting response') {
          getCurrentTripDetails(current_trip_id, false);
        }
      }
    });
  }

  Future<void> addFavoritePlace(String type) async {
    try {
      if (getPrediction != null) {
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(getPrediction.placeId);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String lat = detail.result.geometry.location.lat.toString();
        String lng = detail.result.geometry.location.lng.toString();
        DatabaseReference ref = FirebaseDatabase.instance
            .reference()
            .child('users/${_email.replaceAll('.', ',')}/places');
        String id = ref.push().key;
        ref.child(id).set({
          'id': id,
          'loc_name': loc_name,
          'loc_address': loc_address,
          'latitude': lat,
          'longitude': lng,
          'type': type
        });
      }
    } catch (e) {}
  }

  void displayBottomDialog() {
    setState(() {
      isBottomSheet = true;
      request_progress = null;
    });
    setModeForDestination('request');
    getDistanceDuration();
  }

  void getDistanceDuration() {
    try {
      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${current_location.loc_address.replaceAll(' ', '%20')}&destinations=${destination_location.loc_address.replaceAll(' ', '%20')}&key=$api_key';
      //print(url);
      http.get(url).then((res) {
        //new Utils().neverSatisfied(context, 'response', '${res.body}');
        //print(res.body);
        Map<String, dynamic> resp = json.decode(res.body);
        String status = resp['status'];
        //new Utils().neverSatisfied(context, 'status', '$status');
        if (status != null && status == 'OK') {
          Map<String, dynamic> result = resp['rows'][0];
          Map<String, dynamic> element = result['elements'][0];
          Map<String, dynamic> distance = element['distance'];
          Map<String, dynamic> duration = element['duration'];
          //new Utils().neverSatisfied(context, 'distance', distance['text']);
          setState(() {
            trip_distance = distance['text'];
            trip_duration = duration['text'];
            isLoaded = true;
            errorLoaded = '';
            request_progress = 0.0;
          });
        } else {
          //new Utils().neverSatisfied(context, 'after if', 'sth wrong');
          setState(() {
            request_progress = 0.0;
            errorLoaded = 'An error occured. Please try again.';
          });
        }
      });
    } catch (e) {
      new Utils().neverSatisfied(context, 'error', '${e.toString()}');
    }
  }

  Future<void> listenForDestinationEntered() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.once().then((val) {
      if (val != null) {
        String value = val.value;
        if (value == 'none') {
          setState(() {
            isBottomSheet = false;
          });
          _locationSubscription.resume();
        }
      }
    });
  }

  Future<void> setModeForDestination(String value) async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.set(value);
  }

  Future<void> getCurrentTripDetails(
      String current_trip_id, bool review_driver) async {
    DatabaseReference tripRef2 = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips/$current_trip_id');
    await tripRef2.once().then((snapshot) {
      setState(() {
        currentTrip = CurrentTrip.fromSnapshot(snapshot);
        current_location = currentTrip.current_location;
        destination_location = currentTrip.destination;
        if (review_driver) {
          Route route = MaterialPageRoute(
              builder: (context) => ReviewDriver(currentTrip.assigned_driver));
          Navigator.pushReplacement(context, route);
        }
        if (currentTrip.assigned_driver != 'none' &&
            currentTrip.assigned_driver.contains('@')) {
          getDriverDetails(currentTrip.assigned_driver);
        }
      });
    });
  }

  Future<void> getDriverDetails(String assigned_driver) async {
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${assigned_driver.replaceAll('.', ',')}');
    await driverRef.child('signup').once().then((snapshot) {
      setState(() {
        driverDetails = DriverDetails.fromSnapshot(snapshot);
      });
    });
    driverRef.child('location').onValue.listen((data) {
      double latitude = double.parse(data.snapshot.value['latitude']);
      double longitude = double.parse(data.snapshot.value['longitude']);
      getDriverDistanceDuration(latitude, longitude);
    });
  }

  void getDriverDistanceDuration(double lat, double lng) {
    String latlng = '$lat,$lng';
    String current = _currentLocation['latitude'].toString() +
        "," +
        _currentLocation['longitude'].toString();
    String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$latlng&destinations=$current&key=$api_key';
    print(url);
    http.get(url).then((res) async {
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['rows'][0];
        Map<String, dynamic> element = result['elements'][0];
        Map<String, dynamic> distance = element['distance'];
        Map<String, dynamic> duration = element['duration'];
        String driver_distance = distance['text'];
        String driver_duration = duration['text'];
        setState(() {
          appBarTitle = 'Rider arrives in $driver_duration';
        });
        updateMapCamera(lat, lng);
      }
    });
  }
}

Future<Null> displayPrediction(Prediction p, ScaffoldState scaffold) async {
  if (p != null) {
    // get detail (lat/lng)
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
    String loc_name = detail.result.name;
    String loc_address = detail.result.formattedAddress;
    String lat = detail.result.geometry.location.lat.toString();
    String lng = detail.result.geometry.location.lng.toString();
    FavoritePlaces p_fp =
        FavoritePlaces('', loc_name, loc_address, lat, lng, 'history');
    isSavedPlace = true;
    Navigator.pop(scaffold.context, p_fp);
  }
}

class CustomSearchScaffold extends PlacesAutocompleteWidget {
  CustomSearchScaffold()
      : super(
          apiKey: kGoogleApiKey,
        );

  @override
  _CustomSearchScaffoldState createState() => _CustomSearchScaffoldState();
}

class _CustomSearchScaffoldState extends PlacesAutocompleteState {
  List<FavoritePlaces> _fav_places = new List();

  @override
  Widget build(BuildContext context) {
    loadFavoritePlaces();
    final appBar = AppBar(
      title: AppBarPlacesAutoCompleteTextField(),
      leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          }),
    );
    final body = PlacesAutocompleteResult(
      onTap: (p) {
        displayPrediction(p, searchScaffoldKey.currentState);
      },
      logo: ListView(
        children: getMorePlaces(),
      ),
    );
    return Scaffold(key: searchScaffoldKey, appBar: appBar, body: body);
  }

  Future<void> loadFavoritePlaces() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/places');
    await ref.once().then((snapshot) {
      if (snapshot.value != null) {
        _fav_places.clear();
        setState(() {
          for (var value in snapshot.value.values) {
            FavoritePlaces fp = new FavoritePlaces.fromJson(value);
            _fav_places.add(fp);
          }
        });
      }
    }).whenComplete(() {});
  }

  List<Widget> getMorePlaces() {
    List<Widget> m = new List();
    for (var i = 0; i < _fav_places.length; i++) {
      FavoritePlaces fp = _fav_places[i];
      m.add(new Container(
          margin: EdgeInsets.only(left: 0.0),
          color: Colors.white,
          child: new ListTile(
            leading: Icon(
              Icons.location_on,
              color: Colors.grey,
            ),
            title: Text(
              '${fp.loc_name}',
              style: TextStyle(
                  color: Color(MyColors().primary_color), fontSize: 16.0),
            ),
            onTap: () {
              FavoritePlaces selected_fp = fp;
              Navigator.pop(context, selected_fp);
            },
          )));
    }
    return m;
  }

  @override
  void onResponseError(PlacesAutocompleteResponse response) {
    super.onResponseError(response);
//    searchScaffoldKey.currentState.showSnackBar(
//      SnackBar(content: Text(response.errorMessage)),
//    );
  }

  @override
  void onResponse(PlacesAutocompleteResponse response) {
    super.onResponse(response);
//    if (response != null && response.predictions.isNotEmpty) {
//      searchScaffoldKey.currentState.showSnackBar(
//        SnackBar(content: Text("Got answer")),
//      );
//    }
  }
}
