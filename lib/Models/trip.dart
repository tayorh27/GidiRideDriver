import 'package:firebase_database/firebase_database.dart';
import 'package:gidi_ride_driver/Models/fares.dart';
import 'package:gidi_ride_driver/Models/favorite_places.dart';
import 'package:gidi_ride_driver/Models/general_promotion.dart';
import 'package:gidi_ride_driver/Models/payment_method.dart';

class CurrentTrip {
  String id,
      trip_distance,
      trip_duration,
      vehicle_type,
      scheduled_date,
      status,
      created_date,
      price_range,
  trip_total_price,
      assigned_driver;
  FavoritePlaces current_location, destination;
  PaymentMethods payment_method;
  GeneralPromotions promotion;
  bool card_trip, promo_used;
  Fares fare;

  CurrentTrip.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.value['id'];
    current_location =
        FavoritePlaces.fromSnapshot(snapshot.value['current_location']);
    destination = FavoritePlaces.fromSnapshot(snapshot.value['destination']);
    trip_distance = snapshot.value['trip_distance'];
    trip_duration = snapshot.value['trip_duration'];
    payment_method = (snapshot.value['card_trip'])
        ? PaymentMethods.fromSnapShot(snapshot.value['payment_method'])
        : null;
    vehicle_type = snapshot.value['vehicle_type'];
    promotion = (snapshot.value['promo_used'])
        ? GeneralPromotions.fromSnapShot(snapshot.value['promotion'])
        : null;
    card_trip = snapshot.value['card_trip'];
    promo_used = snapshot.value['promo_used'];
    scheduled_date = snapshot.value['scheduled_date'];
    status = snapshot.value['status'];
    created_date = snapshot.value['created_date'];
    price_range = snapshot.value['price_range'];
    trip_total_price = snapshot.value['trip_total_price'];
    fare = Fares.fromSnapshot(snapshot.value['fare']);
    assigned_driver = snapshot.value['assigned_driver'];
  }
}
