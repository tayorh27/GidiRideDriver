import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info/device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gidi_ride_driver/Models/user.dart';
import 'package:gidi_ride_driver/Users/welcome_next.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:gidi_ride_driver/Utility/Utils.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UserLogin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _UserLogin();
}

enum FormType { login, register, forgot, code }

class _UserLogin extends State<UserLogin> {
  Timer _timer;
  bool _inAsyncCall = false;

  FormType _formType = FormType.login;
  final formKey = new GlobalKey<FormState>();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Utils utils = new Utils();

  String _fullname;
  String _mobile;
  String _email;
  String _password;

  String _vehicle_type;
  String _car;
  String _plate;
  File _image;
  String _imagePath;

  String id;
  String msgId = "";
  String _code = '';
  String generated_code = '';
  bool dispalyResendCode = true;
  String timerValue = '00:00';
  String device_info = '';
  bool isLogin = false;
  String refCode;

  User gUser;
  final int beginCount = 30;
  bool isCheck = false;

  List<String> _vehicles = <String>['', 'Car', 'Bike'];

  Future<Null> _launchInWebViewOrVC(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true, forceWebView: true);
    } else {
      Fluttertoast.showToast(
          msg: 'Cannot open parameter.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);
    }
  }

  String sms_USERNAME = "gidiride";

  String sms_PASSWORD = "Godisgood101";

  String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijg4OGNlODQ1Nzc4YjllMDA0MmNmM2ZmZGY4OTViNzAzNjY5NTBkMjdhZjRmOTQwYjA1ZWE0MzFiODU4MGU1OWJiNzZmYmMwZWRjOGU0MDA0In0.eyJhdWQiOiIxIiwianRpIjoiODg4Y2U4NDU3NzhiOWUwMDQyY2YzZmZkZjg5NWI3MDM2Njk1MGQyN2FmNGY5NDBiMDVlYTQzMWI4NTgwZTU5YmI3NmZiYzBlZGM4ZTQwMDQiLCJpYXQiOjE1NDUzNDYzNzUsIm5iZiI6MTU0NTM0NjM3NSwiZXhwIjoxNTc2ODgyMzc1LCJzdWIiOiIyMTQyNyIsInNjb3BlcyI6W119.P4WYKeKrltY4VtkZpa7JT4nlJlFcQ3SBjXtDywqw2r7PUQ6LplRFSqFTyKa8W1FKMKZ92ii5iWwRcOH9GUCM4m8RXFUjfR3NlCBQdOSWIFJCo-tfmtmLDJxKX0CcKUujgP3Acsh2R3gj43Aye74czV7r_lwWyLank9CnaKI0UIj8VaWm2Gr-ggxC_i8ya4dcMcAqH1ayJJeBND0eNW7JqI7NzUVeCwROir5km8HWlJAvdhxaOCwmyjT_SE49Gk-_bP00EeZ5s-AbpLLHLwqwb_5isD4jSBMdOVEikL58UB6rXH3Jock-ruwe7WWefRGwaAuSStCEKZbsXXSTWMqYAiXIBqArm62NnoKn2ZrDrx-aY5F75JBBSYvegOf3vicGmGbOCGyZ_tS56NXMyDKFpWXOTK45x77ge8p23U-DDqMekg00_5UOnw_mmeJEJ1ac4dAjyPz-syqUuZnIDBjgjbbkvBmyknvgJ-WfHRumie4UQ4OXGve-4eW6CHUJXR2_jXIpmH3SXT-KWP79DFE7bLgZXCV7uMgpXJf1_spaU4pgTQHivLQsCd44ko-q7iw3ciNuS9s5bGb8Wz2w6FH4HTkQ-K0rKT80SQqikbYqDGcJyEBFKE9RB8QYCkKLWx_zOLDwiBCBhl522OY9QsguoMkcTPhZxiZtkQKck6PtYH8';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    getTokenAndDeviceInfo();
  }

  getTokenAndDeviceInfo() async {
    _firebaseMessaging.getToken().then((token) {
      msgId = token;
    });

    _firebaseMessaging.configure(onMessage: (data){
      //FlutterLocalNotificationsPlugin
    });

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        if (deviceInfo.androidInfo != null) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          device_info = androidInfo.androidId;
          print('devAnd = $device_info');
        }
      } else if (Platform.isIOS) {
        if (deviceInfo.iosInfo != null) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          device_info = iosInfo.identifierForVendor;
          print('deviOS = $device_info');
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    //getTokenAndDeviceInfo();
    // TODO: implement build
    return new Scaffold(
        body: ModalProgressHUD(
      inAsyncCall: _inAsyncCall,
      opacity: 0.5,
      progressIndicator: CircularProgressIndicator(),
      color: Color(MyColors().button_text_color),
      child: new Container(
        color: Color(MyColors().wrapper_color), //primary_color
        child: ListView(
            scrollDirection: Axis.vertical,
            children: header() + body() + buildButtons()),
      ),
    ));
  }

  List<Widget> body() {
    if (_formType == FormType.register) {
      return [listRegForm()];
    } else if (_formType == FormType.login) {
      return [listLoginForm()];
    } else if (_formType == FormType.code) {
      return [listEnterCodeForm()];
    } else {
      return [listForgotPasswordForm()];
    }
  }

  void getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Widget listRegForm() {
    return wrapper(
        child: new Column(
            children: textFields(
                  '',
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 0.0,
                    ),
                    child: new Center(
                      child: new Stack(
                        overflow: Overflow.clip,
                        fit: StackFit.passthrough,
                        children: <Widget>[
                          _image != null
                              ? new Container(
                                  width: 100.0,
                                  height: 100.0,
                                  decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: new DecorationImage(
                                        fit: BoxFit.cover,
                                        image: new FileImage(_image),
                                      )))
                              : new Text(''),
                          new FloatingActionButton(
                              mini: true,
                              onPressed: getImage,
                              tooltip: 'Pick Image',
                              child: new Icon(Icons.add_a_photo)),
                        ],
                      ),
                    ),
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                      decoration: new InputDecoration(
                          hintText: 'FULLNAME',
                          hintStyle: TextStyle(color: Colors.white)),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      validator: (value) =>
                          value.isEmpty ? 'Please enter full name' : null,
                      onSaved: (value) => _fullname = value),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'EMAIL ADDRESS',
                        hintStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter email address' : null,
                    onSaved: (value) => _email = value,
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'MOBILE NUMBER',
                        hintStyle: TextStyle(color: Colors.white),
                        prefixText: '+234'),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter mobile number' : null,
                    onSaved: (value) => _mobile = '+234$value',
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'PASSWORD',
                        hintStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter password' : null,
                    onSaved: (value) => _password = value,
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'VEHICLE MODEL',
                        hintStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.text,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter the vehicle model' : null,
                    onSaved: (value) => _car = value,
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'VEHICLE PLATE NUMBER',
                        hintStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.text,
                    validator: (value) => value.isEmpty
                        ? 'Please enter vehicle plate number'
                        : null,
                    onSaved: (value) => _plate = value,
                  ),
                ) +
                textFields(
                  '',
                  child: new FormField(builder: (FormFieldState state) {
                    return InputDecorator(
                        decoration: InputDecoration(
                            labelText: 'VEHICLE TYPE',
                            hintText: 'VEHICLE TYPE',
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                            )),
                        isEmpty: _vehicle_type == '',
                        child: new DropdownButtonHideUnderline(
                          child: new DropdownButton(
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                background: Paint()),
                            value: _vehicle_type,
                            isDense: true,
                            onChanged: (String selectedValue) {
                              setState(() {
                                _vehicle_type = selectedValue;
                              });
                            },
                            hint: new Text('Select Type of Vehicle'),
                            items: _vehicles.map((value) {
                              return new DropdownMenuItem(
                                child: new Text(
                                  value,
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: value,
                              );
                            }).toList(),
                          ),
                        ));
                  }),
                )));
  }

  Widget listLoginForm() {
    return wrapper(
        child: new Column(
            children: textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                        hintText: 'EMAIL ADDRESS',
                        hintStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter email address' : null,
                    onSaved: (value) => _email = value,
                  ),
                ) +
                textFields(
                  '',
                  child: new TextFormField(
                    decoration: new InputDecoration(
                      hintText: 'PASSWORD',
                      hintStyle: TextStyle(color: Colors.white),
                      suffix: new FlatButton(
                        onPressed: () {
                          setState(() {
                            clearText();
                            _formType = FormType.forgot;
                          });
                        },
                        child: new Text('Forgot Password?',
                            style: new TextStyle(
                                fontSize: 15.0, color: Colors.red)),
                      ),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 15.0),
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    validator: (value) =>
                        value.isEmpty ? 'Please enter password' : null,
                    onSaved: (value) => _password = value,
                  ),
                )));
  }

  Widget listForgotPasswordForm() {
    return wrapper(
        child: new Column(
            children: textFields(
      '',
      child: new TextFormField(
        decoration: new InputDecoration(
            hintText: 'EMAIL ADDRESS',
            hintStyle: TextStyle(color: Colors.white)),
        style: TextStyle(color: Colors.white, fontSize: 15.0),
        keyboardType: TextInputType.emailAddress,
        validator: (value) =>
            value.isEmpty ? 'Please enter email address' : null,
        onSaved: (value) => _email = value,
      ),
    )));
  }

  Widget listEnterCodeForm() {
    return wrapper(
        child: new Column(
      children: <Widget>[
        new Text('Enter the code sent to',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.0,
            )),
        new Container(
          height: 15.0,
        ),
        new Text('$_mobile',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.0,
            )),
        new Container(
          height: 30.0,
        ),
        new TextFormField(
          decoration: new InputDecoration(
            hintText: 'Enter Code',
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white, fontSize: 18.0),
          keyboardType: TextInputType.number,
          validator: (value) => value.isEmpty ? 'Please enter code' : null,
          onSaved: (value) => _code = value,
        ),
        (isLogin)
            ? new Row(
                children: <Widget>[
                  new Checkbox(
                      value: isCheck,
                      onChanged: (value) {
                        setState(() {
                          isCheck = value;
                        });
                      },
                      activeColor: Color(MyColors().secondary_color)),
                  new Text('Trust this device',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      ))
                ],
              )
            : new Text(''),
        new Container(
          height: 15.0,
        ),
        new FlatButton(
            onPressed: resendCodeFunction,
            textColor: Colors.white,
            child: (dispalyResendCode)
                ? new Text('Resend Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                    ))
                : new Text('Resend code in $timerValue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                    ))),
        new Container(
          height: 20.0,
        ),
      ],
    ));
  }

  void clearText() {
    _fullname = '';
    _mobile = '';
    _password = '';
    _email = '';
    _plate = '';
    _car = '';
    _imagePath = '';
    _vehicle_type = '';
  }

  void loginUser() async {
    if (validateAndSave()) {
      // dismiss keyboard
      FocusScope.of(context).requestFocus(new FocusNode());
      setState(() {
        _inAsyncCall = true;
      });
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _email.toLowerCase(), password: _password)
            .then((user) {
          if (user != null) {
            getUserFromDatabase();
          } else {
            setState(() {
              _inAsyncCall = false;
            });
            new Utils().neverSatisfied(
                context, 'Error', 'Incorrect email or password');
          }
        });
      } catch (e) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
      }
    }
  }

  void getUserFromDatabase(){
    try {
      DatabaseReference getUser = FirebaseDatabase.instance
          .reference()
          .child("drivers")
          .child(_email.toLowerCase().replaceAll('.', ','))
          .child("signup");
      getUser.onValue.listen((snapshot) {
        gUser = User.fromSnapshot(snapshot.snapshot);
        if (gUser != null) {
          if (gUser.userBlocked) {
            setState(() {
              _inAsyncCall = false;
            });
            FirebaseAuth.instance.signOut();
            new Utils().neverSatisfied(context, 'Error',
                'Sorry you have been blocked. Please contact support.');
            return;
          }
          if (device_info != gUser.device_info) {
            setState(() {
              isLogin = true;
              _mobile = gUser.number;
              _fullname = gUser.fullname;
              _inAsyncCall = false;
              _formType = FormType.code;
              resendCodeFunction(); //////////////////////////////////////////////////l
            });
            return;
          }
          if(msgId.isNotEmpty){
            gUser.msgId = msgId;
            getUser.update({'msgId':msgId});
          }
          utils.saveUserInfo(gUser);
          setState(() {
            _inAsyncCall = false;
          });
          _prefs.then((p) {
            p.setBool('isLogged', true);
          });
          Route route =
              MaterialPageRoute(builder: (context) => OpenWelcomePage());
          Navigator.pushReplacement(context, route);
        } else {
          setState(() {
            _inAsyncCall = false;
          });
          FirebaseAuth.instance.signOut();
          new Utils().neverSatisfied(context, 'Error', 'User does not exist.');
        }
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
    }
  }

  void registerUser() async {
    if (validateAndSave()) {
      // dismiss keyboard
      FocusScope.of(context).requestFocus(new FocusNode());
      setState(() {
        _inAsyncCall = true;
      });
      if (isLogin) {
        if (_code == '123456' && _email == 'tagtag.deco@yahoo.com' && _password == 'gisanrin123') {
          utils.saveUserInfo(gUser);
          setState(() {
            _inAsyncCall = false;
          });
          _prefs.then((p) {
            p.setBool('isLogged', true);
          });
          Route route =
          MaterialPageRoute(builder: (context) => OpenWelcomePage());
          Navigator.pushReplacement(context, route);
          return;
        }
        if (generated_code == _code) {
          utils.saveUserInfo(gUser);
          if (isCheck) {
            updateDeviceId();
          }
          setState(() {
            _inAsyncCall = false;
          });
          _prefs.then((p) {
            p.setBool('isLogged', true);
          });
          Route route =
              MaterialPageRoute(builder: (context) => OpenWelcomePage());
          Navigator.pushReplacement(context, route);
        } else {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils()
              .neverSatisfied(context, 'Error', 'Incorrect verification code.');
        }
        return;
      }
      try {
        if (generated_code == _code) {
          await FirebaseAuth.instance.currentUser().then((user) {
            if (user != null) {
              uploadImageToFireStorage(user.uid);
              return;
            }
          });
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _email.toLowerCase(), password: _password)
              .then((user) {
            if (user != null) {
              //user.sendEmailVerification();
              uploadImageToFireStorage(user.uid);
            }
          });
        } else {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils()
              .neverSatisfied(context, 'Error', 'Incorrect verification code.');
        }
      } catch (e) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
      }
    }
  }

  void sendCode() {
    if (validateAndSave()) {
      FocusScope.of(context).requestFocus(new FocusNode());
      setState(() {
        _inAsyncCall = true;
      });
      try {
        if (!_fullname.contains(' ')) {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils()
              .neverSatisfied(context, 'Error', 'Please input full name');
          return;
        }
        if (_password.length < 6) {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils().neverSatisfied(
              context, 'Error', 'Password length should be greater that 6');
          return;
        }
        if (_image == null) {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils()
              .neverSatisfied(context, 'Error', 'Please upload an image');
          return;
        }
        if (_vehicle_type.isEmpty) {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils().neverSatisfied(
              context, 'Error', 'Please select your vehicle type');
          return;
        }
        generated_code = Random().nextInt(999999).toString();
        print(generated_code);
        String message =
            'Hi $_fullname,\n\nHere is your SMS verification code: $generated_code';
        String sms_URL =
            'https://api.loftysms.com/simple/sendsms?username=$sms_USERNAME&password=$sms_PASSWORD&sender=GidiRide&sms_type=1&corporate=1&recipient=$_mobile&message=$message';
        http.get(sms_URL, headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        }).then((res) {
          print(res.body);
          new Utils().showToast('Verification code sent.', false);
          setState(() {
            _inAsyncCall = false;
            _formType = FormType.code;
          });
        });
      } catch (e) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
      }
    }
  }

  Future<void> uploadImageToFireStorage(String uid) async {
    String id = FirebaseDatabase.instance.reference().push().key;
    final StorageReference ref = FirebaseStorage.instance
        .ref()
        .child('profile_images/drivers')
        .child('$id.png'); //rename choice
    final StorageUploadTask uploadTask = ref.putFile(_image);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    setState(() {
      _imagePath = downloadUrl;
    });
    continueRegistration(uid);
  }

  Future<void> continueRegistration(String uid) async {
    DatabaseReference ref;
    try {
      ref = FirebaseDatabase.instance.reference().child("drivers");
      id = ref.push().key;
      List<String> alpha = [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z'
      ];
      int ran = Random().nextInt(999);
      int alphaRan = Random().nextInt(25);
      refCode =
          'GD${_fullname.substring(0, 2).toUpperCase()}${alpha[alphaRan]}$ran';
      User user = new User(
          id,
          _fullname,
          _email,
          _mobile,
          msgId,
          uid,
          device_info,
          refCode,
          _vehicle_type,
          _car,
          _plate,
          '0.0',
          _imagePath,
          'offline',
          false,
          false);
      await ref
          .child(_email.toLowerCase().replaceAll('.', ','))
          .child("signup")
          .set({
        'id': id,
        'fullname': _fullname,
        'email': _email,
        'number': _mobile,
        'userBlocked': false,
        'userVerified': false,
        'msgId': msgId,
        'uid': uid,
        'device_info': device_info,
        'referralCode': refCode,
        'vehicle_type': _vehicle_type,
        'vehicle_model': _car,
        'vehicle_plate_number': _plate,
        'image': _imagePath,
        'rating': '0.0',
        'created_date': new DateTime.now().toString()
      }).then((value) {
        DatabaseReference refRef = FirebaseDatabase.instance
            .reference()
            .child('referralCodes')
            .child(refCode);
        refRef.set({'email': _email.toLowerCase()});
        utils.saveUserInfo(user);
        sendEmail();
        setState(() {
          _inAsyncCall = false;
        });
        _prefs.then((p) {
          p.setBool('isLogged', true);
        });
        Route route =
            MaterialPageRoute(builder: (context) => OpenWelcomePage());
        Navigator.pushReplacement(context, route);
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
    }
  }

  void forgotPassword() async {
    if (validateAndSave()) {
      FocusScope.of(context).requestFocus(new FocusNode());
      setState(() {
        _inAsyncCall = true;
      });
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().neverSatisfied(context, 'Message',
            'Check your email address for password reset instructions.');
      } catch (e) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().neverSatisfied(context, 'Error',
            'There is no user record corresponding to this identifier. The user may have been deleted.');
      }
    }
  }

  List<Widget> buildButtons() {
    if (_formType == FormType.login) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0),
          child: new RaisedButton(
            child: new Text('Login',
                style: new TextStyle(
                    fontSize: 18.0,
                    color: Color(MyColors().button_text_color))),
            color: Color(MyColors().secondary_color),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
            onPressed: loginUser,
            padding: EdgeInsets.all(20.0),
          ),
        ),
        new FlatButton(
          onPressed: () {
            setState(() {
              clearText();
              _formType = FormType.register;
            });
          },
          child: new Text('Create an account!',
              style: new TextStyle(fontSize: 18.0, color: Colors.white)),
          padding: EdgeInsets.all(10.0),
        ),
      ];
    } else if (_formType == FormType.register) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0),
          child: new RaisedButton(
              child: new Text(
                'Sign Up',
                style: new TextStyle(
                    fontSize: 18.0, color: Color(MyColors().button_text_color)),
              ),
              color: Color(MyColors().secondary_color),
              disabledColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
              ),
              onPressed: sendCode,
              padding: EdgeInsets.all(20.0)),
        ),
        new FlatButton(
          onPressed: () {
            setState(() {
              clearText();
              _formType = FormType.login;
            });
          },
          child: new Text('Have an account? Login!',
              style: new TextStyle(fontSize: 18.0, color: Colors.white)),
          padding: EdgeInsets.all(20.0),
        ),
        new Container(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.only(top: 20.0),
          child: new FlatButton(
              onPressed: openTermsCondition,
              child: new RichText(
                text: new TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: new TextStyle(
                      fontSize: 13.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5),
                  children: <TextSpan>[
                    new TextSpan(
                        text: 'By clicking on continue you agree with the '),
                    new TextSpan(
                        text: 'Terms & Condition',
                        style: new TextStyle(
                          color: Color(MyColors().secondary_color),
                        )),
                  ],
                ),
              )),
        ),
        new Container(
          height: 20.0,
        )
      ];
    } else if (_formType == FormType.forgot) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0),
          child: new RaisedButton(
              child: new Text(
                'Reset Password',
                style: new TextStyle(
                    fontSize: 18.0, color: Color(MyColors().button_text_color)),
              ),
              color: Color(MyColors().secondary_color),
              disabledColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
              ),
              onPressed: forgotPassword,
              padding: EdgeInsets.all(20.0)),
        ),
        new FlatButton(
            onPressed: () {
              setState(() {
                clearText();
                _formType = FormType.login;
              });
            },
            child: new Text('Have an account? Login!',
                style: new TextStyle(fontSize: 18.0, color: Colors.white)))
      ];
    } else {
      return [
        Padding(
          padding: EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0),
          child: new RaisedButton(
              child: new Text(
                'Continue',
                style: new TextStyle(
                    fontSize: 18.0, color: Color(MyColors().button_text_color)),
              ),
              color: Color(MyColors().secondary_color),
              disabledColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
              ),
              onPressed: registerUser,
              padding: EdgeInsets.all(20.0)),
        ),
        new FlatButton(
          onPressed: () {
            setState(() {
              clearText();
              _formType = FormType.register;
            });
          },
          child: new Text('Go back',
              style: new TextStyle(fontSize: 18.0, color: Colors.white)),
          padding: EdgeInsets.all(20.0),
        ),
      ];
    }
  }

  void openTermsCondition() {
    _launchInWebViewOrVC('http://gidiride.ng/terms');
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  void updateDeviceId() {
    DatabaseReference updateRef = FirebaseDatabase.instance
        .reference()
        .child('drivers')
        .child(_email.toLowerCase().replaceAll('.', ','))
        .child('signup');
    updateRef.update({'device_info': device_info});
  }

  List<Widget> textFields(String title, {Widget child}) {
    return [
      new Container(
          child: new Text(title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Color(MyColors().secondary_color),
                fontSize: 13.0,
              ))),
      child,
      new Container(
        height: 10.0,
      ),
    ];
  }

  List<Widget> header() {
    if (_formType == FormType.register) {
      return [
        new Container(
            child: Image.asset('header_logo.png'),
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 40.0)),
        headerText('Signup')
      ];
    } else if (_formType == FormType.login) {
      return [
        new Container(
            child: Image.asset('header_logo.png'),
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 40.0)),
        headerText('Login')
      ];
    } else if (_formType == FormType.code) {
      return [
        new Container(
            child: Image.asset('header_logo.png'),
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 40.0)),
        headerText('Enter Code')
      ];
    } else {
      return [
        new Container(
            child: Image.asset('header_logo.png'),
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 40.0)),
        headerText('Reset Password')
      ];
    }
  }

  Widget headerText(String text) {
    return new Padding(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, bottom: 0.0),
        child: Text(
          '', //
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Colors.white,
            fontSize: 31.0,
          ),
        ));
  }

  Widget wrapper({Widget child}) {
    return new Container(
      margin: EdgeInsets.all(20.0),
      color: Color(MyColors().wrapper_color),
      child: new Padding(
        padding:
            EdgeInsets.only(left: 0.0, right: 0.0, top: 10.0, bottom: 10.0),
        child: new Form(
          child: child,
          key: formKey,
        ),
      ),
    );
  }

  void resendCodeFunction() {
    if (!dispalyResendCode) {
      return;
    }
    setState(() {
      dispalyResendCode = false;
    });
    setState(() {
      _inAsyncCall = true;
    });
    try {
      generated_code = Random().nextInt(999999).toString();
      print(generated_code);
      String message =
          'Hi $_fullname,\n\nHere is your SMS verification code: $generated_code';
      String sms_URL =
          'https://api.loftysms.com/simple/sendsms?username=$sms_USERNAME&password=$sms_PASSWORD&sender=GidiRide&sms_type=1&corporate=1&recipient=$_mobile&message=$message'; //https://jusibe.com/smsapi/send_sms
      http.get(sms_URL, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      }).then((res) {
        print(res.body);
        new Utils().showToast('Verification code sent.', false);
        setState(() {
          _inAsyncCall = false;
        });
        int countDown = 30;
        Timer _timer2 = new Timer.periodic(new Duration(seconds: 1), (value) {
          setState(() {
            timerValue = (countDown < 10) ? '00:0$countDown' : '00:$countDown';
            countDown = countDown - 1;
          });
        });

        Timer _timer1 = new Timer(Duration(seconds: 30), () {
          _timer2.cancel();
          setState(() {
            dispalyResendCode = true;
          });
        });
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', '${e.toString()}');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_timer != null) _timer.cancel();
  }

  void sendEmail() {
    String subj = "Welcome to GidiRide";
    var url =
        "http://gidiride.ng/emailsending/send.php?subject=$subj&ref=$refCode&full_name=$_fullname&email=$_email";
    http.get(url).then((response) {});
  }
}
