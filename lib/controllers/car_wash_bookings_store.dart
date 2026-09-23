/// In-memory car wash bookings created from the cart Pay flow.
class CarWashBookingsStore {
  CarWashBookingsStore._();
  static final CarWashBookingsStore instance = CarWashBookingsStore._();

  final List<Map<String, dynamic>> bookings = [];

  void add(Map<String, dynamic> booking) {
    bookings.insert(0, booking);
  }
}
