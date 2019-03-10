import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:gidi_ride_driver/Users/home_user.dart';
import 'package:gidi_ride_driver/Utility/MyColors.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class PaymentDetails extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PaymentDetails();
}

class _PaymentDetails extends State<PaymentDetails> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '';
  int _Fcount = 0;

//  List<PaymentMethods> _methods = new List();
//  List<GeneralPromotions> _general_promotions = new List();
//  List<GeneralPromotions> _admin_general_promotions = new List();
//  double progress_payment = null;
//  double progress_promotion = null;
  bool isTripsLoaded = false;
  List<dynamic> _tripsSnapshot = new List();
  List<String> _tripsSnapshotKey = new List();

//
//  final formKey = GlobalKey<FormState>();
//  String promo_entered;
//  double _inAsyncCall = 0.0;
  bool _inAsyncCall = false;

//  bool isFirstTrip = false;
//  bool isPromoExist = false;

  var paystackPublicKey;
  var paystackSecretKey;

  void performOp() {
    DatabaseReference _ref1 = FirebaseDatabase.instance
        .reference()
        .child('drivers/${_email.replaceAll('.', ',')}/trips');
    _ref1.once().then((val) {
      if (val.value != null) {
        setState(() {
          _Fcount = 1;
        });
      }
    });
  }

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
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
      });
    });
    performOp();
    if (!isTripsLoaded) {
      loadTrips();
    }
    // TODO: implement build
    return DefaultTabController(
        length: _tripsSnapshot.length,
        initialIndex: (_tripsSnapshot.length - 1),
        child: Scaffold(
          backgroundColor: Color(MyColors().button_text_color),
          appBar: new AppBar(
            leading: new IconButton(
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserHomePage()));
                }),
            title: Text(
              'Earned History',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            bottom: TabBar(
              tabs: getHeaderTabs(),
              indicatorColor: Color(MyColors().secondary_color),
              labelColor: Colors.white,
              isScrollable: true,
              indicatorWeight: 2.0,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontSize: 20.0, letterSpacing: 1.5),
              unselectedLabelStyle:
                  TextStyle(fontSize: 20.0, letterSpacing: 1.5),
            ),
          ),
          body: TabBarView(
            children: (_Fcount > 0) ? tabViews() : emptyTrip(),
          ),
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
      //print('my key = $key');
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
      List<ChartData> chartData = new List();
      double earned_money = 0;
      item.values.forEach((sub_items) {
        int ind = 1;
        Map<dynamic, dynamic> trip_details = sub_items['trip_details'];
        double amount_earned = double.parse(
            trip_details['trip_total_price'].toString().substring(1));
        earned_money = earned_money + amount_earned;
        chartData.add(new ChartData('Trip $ind', amount_earned.toInt()));
        ind = ind + 1;
        //views.add();
      });
      views.add(buildColumn('$earned_money', chartData));
    }
    return views;
  }

  List<charts.Series> seriesList;

//  factory _PaymentDetails.withSampleData() {
//    return new SimpleBarChart(
//      _createSampleData(),
//      // Disable animations for image tests.
//      animate: true,
//    );
//  }

  List<charts.Series<ChartData, String>> _createChartData(
      List<ChartData> chartData) {
//    final data = [
//      new OrdinalSales('2014', 5),
//      new OrdinalSales('2015', 25),
//      new OrdinalSales('2016', 100),
//      new OrdinalSales('2017', 75),
//    ];

    return [
      new charts.Series<ChartData, String>(
        id: 'Earnings',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartData cd, _) => cd.xValue,
        measureFn: (ChartData cd, _) => cd.yValue,
        data: chartData,
      )
    ];
  }

  Widget buildColumn(String total_amount_earned, List<ChartData> chartData) {
    seriesList = _createChartData(chartData);
//    var series = [
//      new charts.Series(
//        id: 'Earning',
//        domainFn: (ChartData clickData, _) => clickData.xValue,
//        measureFn: (ChartData clickData, _) => clickData.yValue,
//        colorFn: (ChartData clickData, _) =>
//            charts.Color(r: 255, g: 202, b: 64, a: 1),
//        areaColorFn: (ChartData clickData, _) =>
//            charts.Color(r: 255, g: 202, b: 64, a: 1),
//        fillColorFn: (ChartData clickData, _) =>
//            charts.Color(r: 255, g: 202, b: 64, a: 1),
//        data: chartData,
//      ),
//    ];
    var chart = new charts.BarChart(
      seriesList,
      animate: true,
      domainAxis: charts.AxisSpec(
          showAxisLine: true,
          renderSpec: charts.GridlineRendererSpec(
              labelStyle:
                  charts.TextStyleSpec(color: charts.MaterialPalette.white))),
    );

    var chartWidget = new SizedBox(
      height: 200,
      child: chart,
    );

    return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[buildEarned(total_amount_earned), chartWidget]);
  }

//  List<Bar<ChartData, String, int>> getBars(
//      List<ChartData> chartData, BarStack<int> barStack1) {
//    List<Bar<ChartData, String, int>> bars = new List();
//    for (ChartData cd in chartData) {
//      bars.add(new Bar<ChartData, String, int>(
//          xFn: (cha) => cd.xValue,
//          valueFn: (cha) => int.parse(cd.yValue),
//          fill: new PaintOptions.fill(color: Color(MyColors().secondary_color)),
//          stack: barStack1));
//    }
//    return bars;
//  }

  Widget buildEarned(String total_amount_earned) {
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(bottom: 10.0, top: 15.0),
        child: Center(
            child: Container(
          height: 50.0,
          width: 200.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Color(MyColors().primary_color),
              border: Border(
                  top: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  left: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  right: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  bottom: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0)),
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          child: Center(
            child: Text(
              '₦$total_amount_earned',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )));
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
          //print('keys = $key');
          setState(() {
            _tripsSnapshot.add(vals);
            _tripsSnapshotKey.add('$key');
          });
        });
      }
      setState(() {
        //isTripsLoaded = true;
      });
    });
  }

  List<Widget> emptyTrip() {
    return [
      new Container(
          child: new Center(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Icon(
              Icons.cancel,
              color: Colors.white,
              size: 48.0,
            ),
            new Text(
              'You have no data yet.',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(fontSize: 16.0),
            )
          ],
        ),
      ))
    ];
  }
}

class ChartData {
  String xValue;
  int yValue;

  ChartData(this.xValue, this.yValue);
}
