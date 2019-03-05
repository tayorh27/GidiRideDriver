import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gidi_ride_driver/Models/driver.dart';
import 'package:gidi_ride_driver/Models/reviews.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating/flutter_rating.dart';

class ReviewDriver extends StatefulWidget {
  String driver_email;

  ReviewDriver(this.driver_email);

  @override
  State<StatefulWidget> createState() => _ReviewDriver();
}

class _ReviewDriver extends State<ReviewDriver> {

  DriverDetails driverDetails;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email='',_name='';
  final formKey = new GlobalKey<FormState>();
  String comment;
  double rating = 0.0;
  double total_rating = 0.0;
  bool _inAsyncCall = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<void> getDriverDetails() async{
    DatabaseReference driverRef = FirebaseDatabase.instance.reference().child(
        'drivers/${widget.driver_email.replaceAll('.', ',')}');
    await driverRef.child('signup').once().then((snapshot){
      setState(() {
        driverDetails = DriverDetails.fromSnapshot(snapshot);
      });
    });
  }

  Future<void> getDriverReviews() async{
    DatabaseReference driverRef = FirebaseDatabase.instance.reference().child(
        'drivers/${widget.driver_email.replaceAll('.', ',')}');
    await driverRef.child('reviews').once().then((snapshot){
      if(snapshot.value != null){
        setState(() {
          for (var value in snapshot.value.values) {
            Reviews reviews = new Reviews.fromJson(value);
            double rate_star = double.parse(reviews.rate_star);
            total_rating = total_rating + rate_star;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
      });
    });
    getDriverDetails();
    getDriverReviews();
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        appBar: new AppBar(
          title:  new Text('Rate Driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.0,
              )),
        ),
        body:
        new ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            child: new Container(
                color: Color(MyColors().button_text_color),
                margin: EdgeInsets.all(20.0),
                child: new ListView(
              scrollDirection: Axis.vertical,
              children: buildPage(),
            ))));
  }

  List<Widget> buildPage() {
    return [
      new Center(
          child: new Container(
              width: 100.0,
              height: 100.0,
              margin: EdgeInsets.only(top: 50.0),
              decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  image: new DecorationImage(
                    fit: BoxFit.cover,
                    image: (driverDetails != null) ? new NetworkImage(driverDetails.image) : AssetImage('user_dp.png'),
                  )))),
      new Container(
          margin: EdgeInsets.only(top: 20.0),
          child: new Center(
            child: (driverDetails != null) ? new Text(driverDetails.fullname,
                style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)) : new Text(''),
          )),
      new Container(
          margin: EdgeInsets.all(20.0),
          child: new Center(
            child: new Form(
                key: formKey,
                child: new SingleChildScrollView(
                  child: new ListBody(
                    children: <Widget>[
                      new TextFormField(
                        validator: (value) => value.isEmpty
                            ? 'Please write a short comment'
                            : null,
                        onSaved: (value) => comment = value,
                        decoration:
                        new InputDecoration(labelText: 'Enter Commenent'),
                      )
                    ],
                  ),
                )),
          )),
      new Container(
          margin: EdgeInsets.all(30.0),
          child: new Center(
            child: new StarRating(
              rating: rating,
              starCount: 5,
              size: 45.0,
              borderColor: Colors.grey,
              color: Colors.green,
              onRatingChanged: (rate) {
                setState(() {
                  rating = rate;
                });
              },
            ),
          )),
      new Padding(
        padding: EdgeInsets.all(20.0),
        child: new FlatButton(
          onPressed: () {
            submitRating();
          },
          child: new Text('SUBMIT'),
          color: Color(MyColors().secondary_color),
          textColor: Colors.white,
        ),
      )
    ];
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  void submitRating() {
    if (validateAndSave()) {
      if (rating == 0.0) {
        new Utils().neverSatisfied(context, 'Error', 'Please assign a rating.');
        return;
      }
      setState(() {
        _inAsyncCall = true;
      });
      uploadRatings();
    }
  }

  void uploadRatings() {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('drivers')
          .child(widget.driver_email
          .replaceAll('.', ','))
          .child('reviews');
      String id = ref.push().key;
      ref.push().set({
        'id': id,
        'username': _name,
        'user_email': _email,
        'avatar': 'user_dp',
        'comment': comment,
        'date': new DateTime.now().toString(),
        'rate_star': '$rating'
      }).then((complete) {
        deleteTripStatusForUser();
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  void deleteTripStatusForUser() {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(_email.replaceAll('.', ','))
          .child('trips')
          .child('status');
      ref.remove().then((complete) {
        calculateTotalStars();
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  void calculateTotalStars() {
    double tt = total_rating + rating;
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('drivers')
          .child(widget.driver_email.replaceAll('.', ','))
          .child('signup');
      ref.push().set({
        'rating': '$tt',
      }).then((complete) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().showToast('Thank you for choosing GidiRide', false);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => UserHomePage()));
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }
}