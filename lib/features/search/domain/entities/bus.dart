import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Bus.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Bus(
      id: doc.id,
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
      operatorCode: data['operatorCode']?.toString() ?? 'firestore',
      operatorTripId: data['operatorTripId']?.toString(),
    );
  }

  DateTime? get departureDate => null;

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
    };
  }
}
