import '../../../../core/constants/route_pricing.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/bus_search_request.dart';
import '../../domain/repositories/bus_search_provider.dart';

class MockBusSearchProvider implements BusSearchProvider {
  const MockBusSearchProvider();

  @override
  Future<List<Bus>> searchBuses(BusSearchRequest request) async {
    final basePrice = request.fallbackPrice ??
        RoutePricing.priceFor(request.from, request.to);
    final route = [request.from, request.to];

    return [
      Bus(
        id: '1',
        name: 'Kilimanjaro Express',
        type: 'Luxury AC Sleeper',
        departureTime: '06:00 AM',
        arrivalTime: '02:00 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 4.9,
        availableSeats: 54,
        amenities: ['WiFi', 'Charging Port', 'Tv', 'Toilet', 'Water'],
        route: route,
        operatorCode: 'demo',
        operatorTripId: '1',
      ),
      Bus(
        id: '2',
        name: 'Tahmeed Coach',
        type: 'Executive AC Seater',
        departureTime: '08:30 AM',
        arrivalTime: '04:30 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 4.7,
        availableSeats: 54,
        amenities: [
          'WiFi',
          'Extra Legroom',
          'Tv',
          'Toilet',
          'Charging Port',
          'Water',
        ],
        route: route,
        operatorCode: 'demo',
        operatorTripId: '2',
      ),
      Bus(
        id: '3',
        name: 'Dar Express',
        type: 'Semi-Luxury AC',
        departureTime: '10:00 AM',
        arrivalTime: '06:00 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 4.7,
        availableSeats: 54,
        amenities: ['WiFi'],
        route: route,
        operatorCode: 'demo',
        operatorTripId: '3',
      ),
      Bus(
        id: '4',
        name: 'ABC Luxury Coach',
        type: 'VVIP 1 Luxury',
        departureTime: '10:00 AM',
        arrivalTime: '06:00 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 5.7,
        availableSeats: 54,
        amenities: ['WiFi'],
        route: route,
        operatorCode: 'demo',
        operatorTripId: '4',
      ),
      Bus(
        id: '5',
        name: 'Ester Luxury Coach',
        type: 'Semi-Luxury AC',
        departureTime: '10:00 AM',
        arrivalTime: '06:00 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 4.7,
        availableSeats: 54,
        amenities: ['WiFi'],
        route: route,
        operatorCode: 'demo',
        operatorTripId: '5',
      ),
    ];
  }
}
