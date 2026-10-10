class BusSearchRequest {
  final String from;
  final String to;
  final DateTime travelDate;
  final int passengerCount;
  final double? fallbackPrice;

  const BusSearchRequest({
    required this.from,
    required this.to,
    required this.travelDate,
    this.passengerCount = 1,
    this.fallbackPrice,
  });
}
