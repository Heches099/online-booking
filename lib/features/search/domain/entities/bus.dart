class Bus {
  final String id;
  final String name;
  final String type;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;
  final double rating;
  final int availableSeats;
  final List<String> amenities;
  final List<String> route; // List of cities in order
  final String operatorCode;
  final String? operatorTripId;
  final int? abcFromId;
  final int? abcToId;
  final Map<String, String> abcSeatIds;

  Bus({
    required this.id,
    required this.name,
    required this.type,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.rating,
    required this.availableSeats,
    required this.amenities,
    required this.route,
    this.operatorCode = 'local',
    this.operatorTripId,
    this.abcFromId,
    this.abcToId,
    this.abcSeatIds = const {},
  });

  factory Bus.fromFirestore(Map<String, dynamic> data) {
    return Bus(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      departureTime: data['departureTime'] ?? '',
      arrivalTime: data['arrivalTime'] ?? '',
      duration: data['duration'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      availableSeats: data['availableSeats'] ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
      route: List<String>.from(data['route'] ?? []),
      operatorCode: data['operatorCode']?.toString() ?? 'local',
      operatorTripId: data['operatorTripId']?.toString(),
      abcFromId: int.tryParse(data['abcFromId']?.toString() ?? ''),
      abcToId: int.tryParse(data['abcToId']?.toString() ?? ''),
      abcSeatIds: _readStringMap(data['abcSeatIds']),
    );
  }

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value
        .map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  DateTime? get departureDate => null;

  /// true = mtoa huduma halisi wa ABC (redirect flow). Mock/demobasi
  /// yenye jina la ABC lakini operatorCode ya demo hairuhusiwi kulipa.
  bool get isABC => operatorCode.toLowerCase() == 'abc';

  /// Basi la majaribio linalofanana na ABC lakini haina IDs halisi.
  /// Hili lazima LIZUIWE kulipa — wala ZenoPay wala ABC.
  bool get isABCDemo => !isABC && name.toLowerCase().contains('abc');

  /// Exit mock: ABC checkout inaruhusiwa tu kama IDs halisi zipo.
  bool canCheckoutABC(String? seatId) =>
      isABC &&
      (operatorTripId?.trim().isNotEmpty ?? false) &&
      abcFromId != null &&
      abcToId != null &&
      (seatId?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'duration': duration,
      'price': price,
      'rating': rating,
      'availableSeats': availableSeats,
      'amenities': amenities,
      'route': route,
      'operatorCode': operatorCode,
      if (operatorTripId != null) 'operatorTripId': operatorTripId,
      if (abcFromId != null) 'abcFromId': abcFromId,
      if (abcToId != null) 'abcToId': abcToId,
      if (abcSeatIds.isNotEmpty) 'abcSeatIds': abcSeatIds,
    };
  }
}
