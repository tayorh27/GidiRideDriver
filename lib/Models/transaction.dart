class GidiTransaction {
  String id,
      amount,
      reference,
      created_date,
      payment_code,
      payment_type,
      driver,
      rider;
  bool success;

  GidiTransaction(
      this.id,
      this.amount,
      this.reference,
      this.created_date,
      this.payment_code,
      this.payment_type,
      this.driver,
      this.rider,
      this.success);

  Map<String, dynamic> toJSON() {
    return new Map.from({
      'id': id,
      'amount': amount,
      'reference': reference,
      'created_date': created_date,
      'payment_code': payment_code,
      'payment_type': payment_type,
      'driver': driver,
      'rider': rider,
      'success': success
    });
  }
}
