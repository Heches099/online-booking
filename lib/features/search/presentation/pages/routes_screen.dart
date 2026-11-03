import 'package:flutter/material.dart';
import '../../../../core/constants/tanzania_regions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/bus_search_request.dart';
import '../../domain/repositories/bus_search_provider.dart';
import '../../data/providers/mock_bus_search_provider.dart';

class RoutesScreen extends StatefulWidget {
  final String from;
  final String to;
  final DateTime date;
  final double? priceOverride;
  final BusSearchProvider? searchProvider;

  const RoutesScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    this.priceOverride,
    this.searchProvider,
  });

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late Future<List<Bus>> _busesFuture;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  void _loadBuses() {
    final provider = widget.searchProvider ?? const MockBusSearchProvider();
    _busesFuture = provider.searchBuses(
      BusSearchRequest(
        from: widget.from,
        to: widget.to,
        travelDate: widget.date,
        fallbackPrice: widget.priceOverride,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.from} → ${widget.to} Routes'),
      ),
      body: FutureBuilder<List<Bus>>(
        future: _busesFuture,
        builder: (context, snapshot) {
          final buses = snapshot.data ?? const <Bus>[];
          if (buses.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group buses by region
          final groupedBuses = _groupBusesByRegion(buses);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedBuses.length,
            itemBuilder: (context, index) {
              final entry = groupedBuses.entries.elementAt(index);
              final region = entry.key;
              final regionBuses = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRegionHeader(region),
                  const SizedBox(height: 8),
                  ...regionBuses.map((bus) => _buildBusCard(bus)).toList(),
                  // Only show divider if not the last section
                  if (index < groupedBuses.length - 1)
                    const Divider(height: 32, thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.route,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No buses available for this route',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionHeader(String region) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        region,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to seat selection (implementation dependent)
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bus.type,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildRatingBadge(bus.rating),
                      ],
                    ),
                    _buildRouteTimelineSimple(bus),
                    Row(
                      children: bus.amenities
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(_getAmenityIcon(a),
                                    size: 16, color: AppColors.textMuted),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.background.withAlpha(128),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "TZS ",
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: _formatPrice(bus.price),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: const Text(
                        "BOOK NOW",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    if (name.contains('WiFi')) return Icons.wifi_rounded;
    if (name.contains('Charging')) return Icons.bolt_rounded;
    if (name.contains('Water')) return Icons.local_drink_rounded;
    if (name.contains('tea')) return Icons.currency_pound;
    if (name.contains('Breakfast')) return Icons.baby_changing_station;
    if (name.contains('Personal Tv')) return Icons.tv;
    return Icons.star_border_rounded;
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimelineSimple(Bus bus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            bus.departureTime,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary.withAlpha(128)
                  ],
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0,
            child: const Icon(Icons.directions_bus_filled_rounded,
                size: 18, color: AppColors.primary),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withAlpha(128),
                    AppColors.secondary
                  ],
                ),
              ),
            ),
          ),
          Text(
            bus.arrivalTime,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0);
  }

  Map<String, List<Bus>> _groupBusesByRegion(List<Bus> buses) {
    final Map<String, List<Bus>> grouped = {};

    // Initialize with all Tanzania regions
    for (final region in tanzaniaRegions) {
      grouped[region] = [];
    }

    // Group buses by origin region from Tanzania regions constant
    for (final bus in buses) {
      final origin = bus.route.isNotEmpty ? bus.route.first : 'Unknown';
      // Match origin to Tanzania regions (case-insensitive)
      bool matched = false;
      for (final region in tanzaniaRegions) {
        if (origin.toLowerCase().contains(region.toLowerCase())) {
          grouped[region]!.add(bus);
          break;
        }
      }
      // If no match, add to Unknown
      // if (!tanzaniaRegions
      //     .any((r) => origin.toLowerCase().contains(r.toLowerCase()))) {
      //   grouped['Unknown'] ??= [];
      //   grouped['Unknown']!.add(bus);
      // }
      if (!matched) {
        grouped['Unknown'] ??= [];
        grouped['Unknown']!.add(bus);
      }
    }

    // Filter out empty regions but keep the order
    final sorted = <String, List<Bus>>{};
    for (final region in tanzaniaRegions) {
      if (grouped[region]!.isNotEmpty) {
        sorted[region] = grouped[region]!;
      }
    }
    // Add any regions not in the constant list
    grouped.forEach((region, buses) {
      if (!sorted.containsKey(region) && buses.isNotEmpty) {
        sorted[region] = buses;
      }
    });

    return sorted;
  }
}
