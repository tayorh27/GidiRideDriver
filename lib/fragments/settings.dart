import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Users/user_login.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Settings();
}

const kGoogleApiKey =
    "AIzaSyCPSnicnVW3upwwp5Q_MgOkh7FhP3-ab1I"; //"AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();

class _Settings extends State<Settings> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '',
      _name = '',
      _number = '',
      _image = '',
      _vm = '',
      _vpn = '',
      v_type = '';
  List<FavoritePlaces> _fav_places = new List();
  double progress_fav = null;

  FavoritePlaces _home = null;
  FavoritePlaces _work = null;

  String _imagePath;
  bool _inAsyncCall = false;
  final formKey = GlobalKey<FormState>();
  String inputedDialogValue = '';

  void onError(PlacesAutocompleteResponse response) {
    print('error ====== ${response.errorMessage}');
  }

  DatabaseReference updateRef;

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _image = pref.getString('image');
        _vm = pref.getString('vehicle_model');
        _vpn = pref.getString('vehicle_plate_number');
        v_type = pref.getString('vehicle_type');
      });
    });
    updateRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/signup');
    //loadFavoritePlaces();
    // TODO: implement build
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        body: ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            color: Color(MyColors().button_text_color),
            child: new ListView(
              scrollDirection: Axis.vertical,
              children: <Widget>[
                new Container(
                    margin: EdgeInsets.only(top: 20.0),
                    color: Color(MyColors().button_text_color),
                    padding: EdgeInsets.all(8.0),
                    child: new ListTile(
                      leading: (_image.isEmpty)
                          ? CircleAvatar(
                              radius: 30.0,
                              child: Image.asset(
                                'user_dp.png',
                                height: 60.0,
                                width: 60.0,
                              ),
                            )
                          : CircleAvatar(
                              radius: 30.0,
                              child: Image.network(
                                _image,
                                height: 60.0,
                                width: 60.0,
                              ),
                            ),
                      title: new Text(
                        _name,
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      subtitle: new Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          new Container(
                            height: 5.0,
                          ),
                          new Text(
                            _email,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.0),
                          ),
                          new Container(
                            height: 5.0,
                          ),
                          new Text(
                            _number,
                            style:
                                TextStyle(color: Colors.white, fontSize: 12.0),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: _changeProfileImage,
                    )),
                new Container(
                  margin: EdgeInsets.only(top: 20.0, left: 20.0),
                  padding: EdgeInsets.all(20.0),
                  child: new Text(
                    'Other Details',
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                ),
                Divider(
                  height: 1.0,
                  color: Color(MyColors().secondary_color),
                ),
                new Container(
                    margin: EdgeInsets.only(left: 20.0),
                    child: new ListTile(
                      leading: Icon(
                        (v_type.toLowerCase() == 'car')
                            ? Icons.directions_car
                            : Icons.directions_bike,
                        color: Colors.white,
                      ),
                      title: Text(
                        'Vehicle Model',
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      subtitle: Text(
                        _vm,
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.white,
                      ),
                      onTap: () {
                        _changeAValue(
                            context, 'vehicle_model', 'VECHILE MODEL');
                      },
                    )),
                Divider(
                  height: 1.0,
                  color: Color(MyColors().secondary_color),
                ),
                new Container(
                    margin: EdgeInsets.only(left: 20.0),
                    child: new ListTile(
                      leading: Icon(
                        Icons.closed_caption,
                        color: Colors.white,
                      ),
                      title: Text(
                        'Vehicle Plate Number',
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      subtitle: Text(
                        _vpn,
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.white,
                      ),
                      onTap: () {
                        _changeAValue(context, 'vehicle_plate_number',
                            'VEHICLE PLATE NUMBER');
                      },
                    )),
                Divider(
                  height: 1.0,
                  color: Color(MyColors().secondary_color),
                ),
//            new Container(
//                margin: EdgeInsets.only(left: 0.0),
//                child: Column(
//                  mainAxisSize: MainAxisSize.max,
//                  crossAxisAlignment: CrossAxisAlignment.stretch,
//                  mainAxisAlignment: MainAxisAlignment.start,
//                  children: getMorePlaces(),
//                )),
//            new Container(
//              margin: EdgeInsets.only(top: 0.0, left: 20.0),
//              padding: EdgeInsets.all(0.0),
//              child: new FlatButton(
//                onPressed: () {
//                  addFavoritePlace('places');
//                },
//                child: Text(
//                  'Add More Places',
//                  textAlign: TextAlign.start,
//                  style: TextStyle(
//                      color: Color(MyColors().secondary_color), fontSize: 16.0),
//                ),
//              ),
//            ),
                new Container(
                  color: Color(MyColors().button_text_color),
                  margin: EdgeInsets.only(top: 50.0),
                  height: 60.0,
                  child: new FlatButton(
                      onPressed: _beforeLogout,
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                            color: Color(MyColors().secondary_color),
                            fontSize: 16.0),
                      )),
                )
              ],
            )));
  }

  Future<Null> _changeAValue(BuildContext ctx, String key, String title) {
    return showDialog<Null>(
      context: ctx,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('ENTER $title'),
          content: new Form(
              key: formKey,
              child: new SingleChildScrollView(
                child: new ListBody(
                  children: <Widget>[
                    new TextFormField(
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) => value.isEmpty
                          ? 'Please enter ${title.toLowerCase()}.'
                          : null,
                      onSaved: (value) => inputedDialogValue = value,
                      decoration: new InputDecoration(
                        labelText: '$title',
                      ),
                    )
                  ],
                ),
              )),
          actions: <Widget>[
            new FlatButton(
              child: new Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                'APPLY',
                style: TextStyle(color: Color(MyColors().button_text_color)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (validateAndSave()) {
                  _updateDatabase(key, inputedDialogValue);
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<void> _changeProfileImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      setState(() {
        _inAsyncCall = false;
      });
      return;
    }
    setState(() {
      _inAsyncCall = true;
    });
    String id = FirebaseDatabase.instance.reference().push().key;
    final StorageReference ref = FirebaseStorage.instance
        .ref()
        .child('profile_images/drivers')
        .child('$id.png'); //rename choice
    final StorageUploadTask uploadTask = ref.putFile(image);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    setState(() {
      _imagePath = downloadUrl;
    });
    _updateDatabase('image', _imagePath);
  }

  List<Widget> getMorePlaces() {
    List<Widget> m = new List();
    for (var i = 0; i < _fav_places.length; i++) {
      FavoritePlaces fp = _fav_places[i];
      if (fp.type != 'home' && fp.type != 'work' && fp.type != 'history') {
        m.add(new Container(
            margin: EdgeInsets.only(left: 20.0),
            child: new ListTile(
              leading: Icon(
                Icons.location_on,
                color: Colors.white,
              ),
              title: Text(
                '${fp.loc_name}',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              trailing: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
              ),
              onTap: () {
                editFavoritePlace(fp.id, fp.type);
              },
              onLongPress: () {
                deleteFavoritePlaces(fp.id);
              },
            )));
        m.add(Divider(
          height: 1.0,
          color: Color(MyColors().secondary_color),
        ));
      }
    }
    return m;
  }

  Future<void> editFavoritePlace(String id, String type) async {
    try {
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.fullscreen,
          // Mode.fullscreen
          onError: onError);
      if (p != null) {
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(p.placeId);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String lat = detail.result.geometry.location.lat.toString();
        String lng = detail.result.geometry.location.lng.toString();
        DatabaseReference ref = FirebaseDatabase.instance
            .reference()
            .child('users/${_email.replaceAll('.', ',')}/places');
        ref.child(id).set({
          'id': id,
          'loc_name': loc_name,
          'loc_address': loc_address,
          'latitude': lat,
          'longitude': lng,
          'type': type
        }).whenComplete(() {
          new Utils().showToast('Updated successfully', false);
        });
      }
    } catch (e) {
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  Future<void> addFavoritePlace(String type) async {
    try {
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.fullscreen,
          // Mode.fullscreen
          onError: onError);
      if (p != null) {
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(p.placeId);
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
        }).whenComplete(() {
          new Utils().showToast('Added successfully', false);
        });
      }
    } catch (e) {
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  Future<void> deleteFavoritePlaces(String id) async {
    DatabaseReference refDelete = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/places/$id');
    await refDelete.remove();
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
            if (fp.type == 'home') {
              _home = fp;
            }
            if (fp.type == 'work') {
              _work = fp;
            }
          }
          progress_fav = 0.0;
        });
      } else {
        setState(() {
          progress_fav = 0.0;
        });
      }
    });
  }

  Future<Null> _beforeLogout() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation Message'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to logout?'),
                //new Text('You\’re like me. I’m never satisfied.'),
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
                style: TextStyle(color: Color(MyColors().wrapper_color)),
              ),
              onPressed: logUserOut,
            ),
          ],
        );
      },
    );
  }

  Future<void> logUserOut() async {
    _prefs.then((pref) {
      pref.clear();
    });
    await FirebaseAuth.instance.signOut();
    Route route = MaterialPageRoute(builder: (context) => UserLogin());
    Navigator.pushReplacement(context, route);
  }

  void _updateDatabase(String key, String value) {
    updateRef.update({key: value}).then((c) {
      _prefs.then((pref) {
        pref.setString(key, value);
      });
      setState(() {
        if (key == 'image') {
          _image = value;
        }
        if (key == 'vehicle_model') {
          _vm = value;
        }
        if (key == 'vehicle_plate_number') {
          _vpn = value;
        }
        if (key == 'vehicle_type') {}
        _inAsyncCall = false;
      });
    });
  }
}
