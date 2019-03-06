import 'package:firebase_database/firebase_database.dart';

class User {

  String id, fullname,email,number,msgId,uid,device_info, referralCode,vehicle_type, vehicle_model,vehicle_plate_number,rating,image,status;
  bool userBlocked, userVerified;

  User(this.id, this.fullname, this.email, this.number, this.msgId,this.uid,this.device_info, this.referralCode, this.vehicle_type, this.vehicle_model, this.vehicle_plate_number, this.rating, this.image,this.status,
      this.userBlocked, this.userVerified);

//  Map<String, dynamic> toJSON() {
//    return new Map.from({
//      'id': id,
//      'fullname': fullname,
//      'number': number,
//      'available': available,
//      'maximum_value': maximum_value,
//      'number_of_rides_used': number_of_rides_used,
//      'promo_code': promo_code,
//      'status': status
//    });
//  }

  User.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.value['id'];
    fullname = snapshot.value['fullname'];
    email = snapshot.value['email'];
    number = snapshot.value['number'];
    msgId = snapshot.value['msgId'];
    uid = snapshot.value['uid'];
    device_info = snapshot.value['device_info'];
    referralCode = snapshot.value['referralCode'];
    vehicle_type = snapshot.value['vehicle_type'];
    vehicle_model = snapshot.value['vehicle_model'];
    vehicle_plate_number = snapshot.value['vehicle_plate_number'];
    rating = snapshot.value['rating'];
    image = snapshot.value['image'];
    status = snapshot.value['status'];
    userBlocked = snapshot.value['userBlocked'];
    userVerified = snapshot.value['userVerified'];
  }

}