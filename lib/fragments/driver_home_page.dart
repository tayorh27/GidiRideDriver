import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:intl/intl.dart';

//import 'package:map_view/map_view.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

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
  String _email = '', _number = '', _name = '', _msg = '';
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
//      _inAsyncCall = false;
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
    //getBookingFares();
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
    //_mapView.markers.clear();
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
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$api_key';
    http.get(url).then((res) async {
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

        locationRef = FirebaseDatabase.instance
            .reference()
            .child('drivers/${_email.replaceAll('.', ',')}/location');
        locationRef.set({
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

//  void showMap() {
//    _mapView.show(new MapOptions(showUserLocation: true,
//      showCompassButton: true,
//      mapViewType: MapViewType.normal,
//      showMyLocationButton: true,));
//  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _msg = pref.getString('msgId');
      });
    });
    // TODO: implement build
    return Scaffold(
      body: new Container(
          child: new Stack(
              overflow: Overflow.clip,
              fit: StackFit.passthrough,
              children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: LatLng(0.0,
                      0.0)),
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
                margin: EdgeInsets.only(top: 60.0, left: 13.0, right: 13.0),
                child: new Column(
                  children: <Widget>[

                  ],
                )),
          ])),
    );
  }
}
