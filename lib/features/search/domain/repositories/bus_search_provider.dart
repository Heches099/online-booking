import '../entities/bus.dart';
import '../entities/bus_search_request.dart';

abstract interface class BusSearchProvider {
  Future<List<Bus>> searchBuses(BusSearchRequest request);
}
