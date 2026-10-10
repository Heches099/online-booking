import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/bus_search_request.dart';
import '../../domain/repositories/bus_search_provider.dart';
import '../../data/providers/mock_bus_search_provider.dart';
import '../../../booking/presentation/pages/seat_selection_page.dart';

class BusResultsPage extends StatefulWidget {
  final String from;
  final String to;
  final DateTime date;
  final double? priceOverride;
  final BusSearchProvider? searchProvider;

  const BusResultsPage({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    this.priceOverride,
    this.searchProvider,
  });

  @override
  State<BusResultsPage> createState() => _BusResultsPageState();
}

class _BusResultsPageState extends State<BusResultsPage> {
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

  String _formatPrice(double price) {
    return NumberFormat.decimalPattern().format(price);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bus>>(
      future: _busesFuture,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? const <Bus>[];
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, buses.length),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildResultsMessage(
                    message:
                        'Could not load buses. Check your connection and retry.',
                    action: 'Retry',
                    onPressed: () => setState(_loadBuses),
                  ),
                )
              else if (buses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildResultsMessage(
                    message: 'No buses are available for this route and date.',
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          duration: const Duration(milliseconds: 600),
                          child: _buildBusCard(context, buses[index]),
                        );
                      },
                      childCount: buses.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsMessage({
    required String message,
    String? action,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onPressed, child: Text(action)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withAlpha(13),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            widget.from,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white70, size: 20),
                          ),
                          Text(
                            widget.to,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.date.day}/${widget.date.month}/${widget.date.year} • 1 Passenger • $count Buses Found",
                        style: TextStyle(
                            color: Colors.white.withAlpha(204), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Bus bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeatSelectionPage(
                bus: bus,
                travelDate: widget.date,
              ),
            ),
          ),
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
                    _buildRouteTimeline(bus),
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

  Widget _buildRouteTimeline(Bus bus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TimePoint(time: bus.departureTime, city: widget.from, isStart: true),
          Expanded(child: _RouteLine(duration: bus.duration)),
          _TimePoint(time: bus.arrivalTime, city: widget.to, isStart: false),
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  final String time;
  final String city;
  final bool isStart;
  const _TimePoint(
      {required this.time, required this.city, required this.isStart});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(time,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          city.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String duration;
  const _RouteLine({required this.duration});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            duration,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withAlpha(77), blurRadius: 4)
                  ],
                ),
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.secondary.withAlpha(77), blurRadius: 4)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
