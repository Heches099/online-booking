import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/route_pricing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/widgets/search_card.dart';
import '../../../search/presentation/pages/bus_results_page.dart';
// import 'dart:math' as math;
import '../../../../core/services/alarm_sound_service.dart';
import '../../../../core/services/local_ticket_storage_service.dart';
import '../../../../core/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AlarmSoundService _alarmSoundService = AlarmSoundService();
  final LocalTicketStorageService _ticketStorageService =
      LocalTicketStorageService();
  final Map<int, bool> _alertOffsets = <int, bool>{
    30: true,
    15: false,
    10: false,
  };

  String? _customSoundUri;
  String? _customSoundName;
  bool _isActivatingAlerts = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _loadDefaultAlarmSound();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAlarmSound() async {
    final sound = await _alarmSoundService.getDefaultAlarmSound();
    if (!mounted || sound == null) return;

    setState(() {
      _customSoundUri = sound.uri;
      _customSoundName = sound.title;
    });
  }

  Future<void> _pickCustomSound() async {
    final sound =
        await _alarmSoundService.pickAlarmSound(currentUri: _customSoundUri);
    if (!mounted || sound == null) return;

    setState(() {
      _customSoundUri = sound.uri;
      _customSoundName = sound.title;
    });
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final maxHeight = MediaQuery.of(context).size.height * 0.85;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "JOURNEY ALERTS",
                        style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Set offline reminder sounds based on your booked tickets.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          await _pickCustomSound();
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.accent.withAlpha(77)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note_rounded,
                                  color: AppColors.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _customSoundName ?? "SELECT ALERT SOUND",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.accent, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAlarmTile(
                        title: "30 MINUTES BEFORE",
                        minutes: 30,
                        isActive: _alertOffsets[30] ?? false,
                        onChanged: (value) {
                          setState(() => _alertOffsets[30] = value);
                          setSheetState(() {});
                        },
                      ),
                      _buildAlarmTile(
                        title: "15 MINUTES BEFORE",
                        minutes: 15,
                        isActive: _alertOffsets[15] ?? false,
                        onChanged: (value) {
                          setState(() => _alertOffsets[15] = value);
                          setSheetState(() {});
                        },
                      ),
                      _buildAlarmTile(
                        title: "10 MINUTES BEFORE",
                        minutes: 10,
                        isActive: _alertOffsets[10] ?? false,
                        onChanged: (value) {
                          setState(() => _alertOffsets[10] = value);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton(
                          onPressed: _isActivatingAlerts
                              ? null
                              : () async {
                                  final activated =
                                      await _activateJourneyAlerts();
                                  if (activated && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: _isActivatingAlerts
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text("ACTIVATE ALERTS",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _activateJourneyAlerts() async {
    final selectedOffsets = _alertOffsets.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (selectedOffsets.isEmpty) {
      _showAlertMessage('Select at least one reminder time.');
      return false;
    }

    setState(() => _isActivatingAlerts = true);

    try {
      final permissionsGranted =
          await NotificationService().ensurePermissions();
      if (!permissionsGranted) {
        _showAlertMessage(
          'Allow notifications to activate journey reminders on this phone.',
        );
        return false;
      }

      final nextTicket = await _ticketStorageService.loadNextUpcomingTicket();
      if (nextTicket == null) {
        await NotificationService().scheduleJourneyAlert(
          id: _notificationIdFor('journey_alert_preview'),
          title: 'Journey alert test',
          body:
              'This is how your reminder for ${_customSoundName ?? 'your default alarm'} will sound.',
          scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
          customSoundUri: _customSoundUri,
        );
        _showAlertMessage(
          'No upcoming ticket found, so a test alert was set for 1 minute from now.',
        );
        return true;
      }

      var scheduledCount = 0;
      for (final minutes in selectedOffsets) {
        final scheduledDate =
            nextTicket.arrivalDateTime.subtract(Duration(minutes: minutes));
        if (!scheduledDate.isAfter(DateTime.now())) {
          continue;
        }

        await NotificationService().scheduleJourneyAlert(
          id: _notificationIdFor('${nextTicket.id}_$minutes'),
          title: '${nextTicket.busName} arrives in $minutes minutes',
          body:
              'Expected arrival in ${nextTicket.to} at ${nextTicket.arrivalTime}.',
          scheduledDate: scheduledDate,
          customSoundUri: _customSoundUri,
        );
        scheduledCount++;
      }

      if (scheduledCount == 0) {
        await NotificationService().scheduleJourneyAlert(
          id: _notificationIdFor('${nextTicket.id}_fallback'),
          title: '${nextTicket.busName} is arriving soon',
          body:
              'Expected arrival in ${nextTicket.to} at ${nextTicket.arrivalTime}.',
          scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
          customSoundUri: _customSoundUri,
        );
        _showAlertMessage(
          'Your trip is too close for the selected offsets, so a reminder was set for 1 minute from now.',
        );
        return true;
      }

      _showAlertMessage(
        'Scheduled $scheduledCount alert${scheduledCount == 1 ? '' : 's'} for ${nextTicket.busName}.',
      );
      return true;
    } finally {
      if (mounted) {
        setState(() => _isActivatingAlerts = false);
      }
    }
  }

  void _showAlertMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  int _notificationIdFor(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }

  Widget _buildAlarmTile({
    required String title,
    required int minutes,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive ? AppColors.accent.withAlpha(77) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded,
              color: isActive ? AppColors.accent : Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          Text(
            '${minutes}m',
            style: TextStyle(
              color: isActive ? AppColors.accent : Colors.white38,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMajesticHeader(context),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMajesticHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      child: Stack(
        children: [
          // Positioned.fill(
          //   child: AnimatedBuilder(
          //     animation: _controller,
          //     builder: (context, child) {
          //       return CustomPaint(
          //         painter: MajesticNaturePainter(progress: _controller.value),
          //       );
          //     },
          //   ),
          // ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInLeft(
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "NEXTGEN",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: 2),
                        ),
                        Text(
                          "ROYAL TRANSPORT",
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  FadeInRight(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white),
                        onPressed: _showNotificationSettings,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: 24,
            child: FadeInDown(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome, Chief",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text("WHERE TO\nEXPLORE?",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                ],
              ),
            ),
          ),
          // Positioned(
          //   bottom: 54,
          //   left: 0,
          //   right: 0,
          //   child: AnimatedBuilder(
          //     animation: _controller,
          //     builder: (context, child) {
          //       final lift = math.sin(_controller.value * math.pi * 2) * 3.5;
          //       final drift = math.sin(_controller.value * math.pi * 2) * 2;
          //       return Transform.translate(
          //         offset: Offset(drift, lift),
          //         child: Center(child: _buildHeroCoachShowcase()),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildHeroCoachShowcase() {
  //   final progress = _controller.value;
  //   final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
  //   final imageDriftX = math.sin(progress * math.pi * 2) * 5;
  //   final imageDriftY = math.cos(progress * math.pi * 2 * 1.2) * 3;

  //   return SizedBox(
  //     width: 360,
  //     height: 210,
  //     child: Stack(
  //       clipBehavior: Clip.none,
  //       children: [
  //         Positioned(
  //           left: 34,
  //           right: 30,
  //           bottom: 8,
  //           child: Container(
  //             height: 36,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(999),
  //               gradient: RadialGradient(
  //                 colors: [
  //                   AppColors.accent.withAlpha(90 + (pulse * 30).round()),
  //                   const Color(0xCC0F172A),
  //                   Colors.transparent,
  //                 ],
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: const Color(0xFF38BDF8)
  //                       .withAlpha(45 + (pulse * 30).round()),
  //                   blurRadius: 40,
  //                   spreadRadius: 6,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         Container(
  //           width: 360,
  //           height: 210,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(34),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withAlpha(97),
  //                 blurRadius: 36,
  //                 offset: const Offset(0, 20),
  //               ),
  //             ],
  //           ),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(34),
  //             child: Stack(
  //               fit: StackFit.expand,
  //               children: [
  //                 const DecoratedBox(
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       colors: [
  //                         Color(0xFF020617),
  //                         Color(0xFF0F172A),
  //                         Color(0xFF102136),
  //                       ],
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                     ),
  //                   ),
  //                 ),
  //                 Transform.translate(
  //                   offset: Offset(imageDriftX, imageDriftY),
  //                   child: Transform.scale(
  //                     scale: 1.04 + (pulse * 0.01),
  //                     child: Image.asset(
  //                       'assets/images/kilimanjaro_royal_express_bus.png',
  //                       fit: BoxFit.cover,
  //                       alignment: const Alignment(-0.08, 0.08),
  //                       filterQuality: FilterQuality.high,
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned.fill(
  //                   child: CustomPaint(
  //                     painter: _HeroShowcaseMotionPainter(progress: progress),
  //                   ),
  //                 ),
  //                 Positioned.fill(
  //                   child: DecoratedBox(
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         colors: [
  //                           const Color(0x7A020617),
  //                           Colors.transparent,
  //                           const Color(0xB3020617),
  //                         ],
  //                         begin: Alignment.topLeft,
  //                         end: Alignment.bottomRight,
  //                         stops: const [0.0, 0.45, 1.0],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned(
  //                   left: 18,
  //                   right: 18,
  //                   bottom: 14,
  //                   child: Container(
  //                     height: 42,
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(24),
  //                       gradient: LinearGradient(
  //                         colors: [
  //                           Colors.transparent,
  //                           Colors.white.withAlpha(20),
  //                           Colors.transparent,
  //                         ],
  //                         begin: Alignment.centerLeft,
  //                         end: Alignment.centerRight,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned.fill(
  //                   child: DecoratedBox(
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(34),
  //                       border: Border.all(color: Colors.white.withAlpha(28)),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         _buildFloatingFeatureChip(
  //           label: "Wi-Fi 6",
  //           icon: Icons.wifi_rounded,
  //           left: 10,
  //           top: 42,
  //           phase: 0.4,
  //           accent: AppColors.accent,
  //         ),
  //         _buildFloatingFeatureChip(
  //           label: "USB-C Power",
  //           icon: Icons.bolt_rounded,
  //           right: 6,
  //           top: 24,
  //           phase: 1.2,
  //           accent: const Color(0xFF60A5FA),
  //         ),
  //         _buildFloatingFeatureChip(
  //           label: "Smart AC",
  //           icon: Icons.ac_unit_rounded,
  //           left: 28,
  //           top: 148,
  //           phase: 2.1,
  //           accent: const Color(0xFF93C5FD),
  //         ),
  //         _buildFloatingFeatureChip(
  //           label: "3-Axle Coach",
  //           icon: Icons.workspace_premium_rounded,
  //           right: 24,
  //           top: 144,
  //           phase: 2.8,
  //           accent: const Color(0xFF38BDF8),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFloatingFeatureChip({
  //   required String label,
  //   required IconData icon,
  //   required double top,
  //   required double phase,
  //   required Color accent,
  //   double? left,
  //   double? right,
  // }) {
  //   final animationValue = (_controller.value * math.pi * 2) + phase;
  //   return Positioned(
  //     left: left,
  //     right: right,
  //     top: top,
  //     child: Transform.translate(
  //       offset: Offset(
  //         math.sin(animationValue) * 4,
  //         math.cos(animationValue * 1.2) * 6,
  //       ),
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //         decoration: BoxDecoration(
  //           color: const Color(0xDD0F172A),
  //           borderRadius: BorderRadius.circular(18),
  //           border: Border.all(color: accent.withAlpha(115)),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withAlpha(89),
  //               blurRadius: 18,
  //               offset: const Offset(0, 12),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(icon, size: 14, color: accent),
  //             const SizedBox(width: 8),
  //             Text(
  //               label,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 11,
  //                 fontWeight: FontWeight.w800,
  //                 letterSpacing: 0.2,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Transform.translate(
            offset: const Offset(0, -60),
            child: FadeInUp(child: const SearchCard()),
          ),
          _buildQuickActionRow(),
          const SizedBox(height: 32),
          _buildSectionHeader("MAJESTIC ROUTES", "VIEW ALL"),
          const SizedBox(height: 20),
          _buildMajesticRoutes(),
          const SizedBox(height: 40),
          _buildLuxuryPromo(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // children: [
      //   _quickAction(Icons.history_rounded, "History"),
      //   _quickAction(Icons.stars_rounded, "Royal Club"),
      //   _quickAction(Icons.location_on_rounded, "Live Track"),
      //   _quickAction(Icons.support_agent_rounded, "Concierge"),
      // ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMajesticRoutes() {
    final routes = [
      _FeaturedRoute(
        label: 'DAR - ARUSHA',
        from: 'Dar es Salaam',
        to: 'Arusha',
        price: RoutePricing.priceFor('Dar es Salaam', 'Arusha'),
      ),
      _FeaturedRoute(
        label: 'DAR - MBEYA',
        from: 'Dar es Salaam',
        to: 'Mbeya',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mbeya'),
      ),
      _FeaturedRoute(
        label: 'DAR - DODOMA',
        from: 'Dar es Salaam',
        to: 'Dodoma',
        price: RoutePricing.priceFor('Dar es Salaam', 'Dodoma'),
      ),
      _FeaturedRoute(
        label: 'DAR - SINGIDA',
        from: 'Dar es Salaam',
        to: 'Singida',
        price: RoutePricing.priceFor('Dar es Salaam', 'Singida'),
      ),
      _FeaturedRoute(
        label: 'DAR - MWANZA',
        from: 'Dar es Salaam',
        to: 'Mwanza',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mwanza'),
      ),
      _FeaturedRoute(
        label: 'DAR - TANGA',
        from: 'Dar es Salaam',
        to: 'Tanga',
        price: RoutePricing.priceFor('Dar es Salaam', 'Tanga'),
      ),
      _FeaturedRoute(
        label: 'DAR - MOROGORO',
        from: 'Dar es Salaam',
        to: 'Morogoro',
        price: RoutePricing.priceFor('Dar es Salaam', 'Morogoro'),
      ),
      _FeaturedRoute(
        label: 'DAR - Mtwara',
        from: 'Dar es Salaam',
        to: 'Mtwara',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mtwara'),
      ),
      _FeaturedRoute(
        label: 'DAR - Kahama',
        from: 'Dar es Salaam',
        to: 'Kahama',
        price: RoutePricing.priceFor('Dar es Salaam', 'Kahama'),
      ),
    ];

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final route = routes[index];
          return _AnimatedRouteCard(
            name: route.label,
            price: route.priceLabel,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusResultsPage(
                    from: route.from,
                    to: route.to,
                    date: DateTime.now(),
                    priceOverride: route.price,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLuxuryPromo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFB8860B), Color(0xFFDAA520)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ROYAL VVIP EXPERIENCE",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const Text(
              "Enjoy gourmet meals and personal iPad TV on our VVIP seats.",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: const Text("EXPLORE VVIP",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRoute {
  final String label;
  final String from;
  final String to;
  final double price;

  const _FeaturedRoute({
    required this.label,
    required this.from,
    required this.to,
    required this.price,
  });

  String get priceLabel => 'TZS ${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      )}';
}

class _AnimatedRouteCard extends StatefulWidget {
  final String name;
  final String price;
  final VoidCallback onTap;

  const _AnimatedRouteCard({
    required this.name,
    required this.price,
    required this.onTap,
  });

  @override
  State<_AnimatedRouteCard> createState() => _AnimatedRouteCardState();
}

class _AnimatedRouteCardState extends State<_AnimatedRouteCard> {
  bool _isPressed = false;

  Color get _normalBorderColor => Colors.white.withAlpha(13);
  Color get _pressedBorderColor => Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isPressed ? _pressedBorderColor : _normalBorderColor,
              width: _isPressed ? 2.0 : 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: _pressedBorderColor.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.landscape_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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
}

// class MajesticNaturePainter extends CustomPainter {
//   final double progress;
//   MajesticNaturePainter({required this.progress});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint();
//     final roadY = size.height - 100;

//     paint.color = Colors.white.withAlpha(77);
//     for (int i = 0; i < 30; i++) {
//       double x = (math.sin(i * 123.45) * 0.5 + 0.5) * size.width;
//       double y = (math.cos(i * 543.21) * 0.5 + 0.5) * (roadY - 100);
//       canvas.drawCircle(Offset(x, y), 1, paint);
//     }

//     paint.color = Colors.white.withAlpha(5);
//     for (int i = -1; i < 2; i++) {
//       double x = (i + (progress * 0.05) % 1.0) * size.width;
//       final path = Path()
//         ..moveTo(x, roadY)
//         ..lineTo(x + size.width * 0.4, roadY - 150)
//         ..lineTo(x + size.width * 0.7, roadY - 80)
//         ..lineTo(x + size.width, roadY)
//         ..close();
//       canvas.drawPath(path, paint);
//     }

//     paint.color = const Color(0xFF1E293B);
//     canvas.drawRect(Rect.fromLTWH(0, roadY, size.width, 100), paint);

//     paint.color = Colors.white.withAlpha(77);
//     double dashW = 80;
//     double dashS = 80;
//     double offset = (progress * 2500) % (dashW + dashS);
//     for (double x = -dashW; x < size.width + dashW; x += (dashW + dashS)) {
//       canvas.drawRRect(
//           RRect.fromRectAndRadius(
//               Rect.fromLTWH(x + offset, roadY + 48, dashW, 4),
//               const Radius.circular(2)),
//           paint);
//     }

//     paint.color = Colors.white.withAlpha(13);
//     for (int i = 0; i < 20; i++) {
//       double x = (i * 80 + (progress * 2500)) % (size.width + 80) - 40;
//       canvas.drawRect(Rect.fromLTWH(x, roadY - 20, 2, 20), paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant MajesticNaturePainter oldDelegate) => true;
// }

// class _HeroShowcaseMotionPainter extends CustomPainter {
//   final double progress;

//   _HeroShowcaseMotionPainter({required this.progress});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rect = Offset.zero & size;
//     final paint = Paint();

//     paint.shader = const LinearGradient(
//       colors: [
//         Color(0x6622D3EE),
//         Color(0x1A0F172A),
//         Color(0x000F172A),
//       ],
//       begin: Alignment.topRight,
//       end: Alignment.centerLeft,
//     ).createShader(rect);
//     canvas.drawRect(rect, paint);

//     paint.shader = const RadialGradient(
//       colors: [
//         Color(0x55F59E0B),
//         Color(0x00F59E0B),
//       ],
//       center: Alignment(-0.9, 0.65),
//       radius: 0.7,
//     ).createShader(rect);
//     canvas.drawRect(rect, paint);

//     for (int i = 0; i < 7; i++) {
//       final travel = ((progress * 1.35) + (i * 0.18)) % 1.4;
//       final startX = -size.width * 0.45 + (travel * size.width * 1.55);
//       final startY = size.height * (0.16 + (i % 5) * 0.11);
//       final endX = startX + size.width * (0.18 + (i % 3) * 0.04);
//       final endY = startY - size.height * 0.08;
//       final streakRect = Rect.fromPoints(
//         Offset(startX, startY),
//         Offset(endX, endY),
//       ).inflate(26);
//       final streakPaint = Paint()
//         ..shader = LinearGradient(
//           colors: [
//             Colors.transparent,
//             const Color(0x66E0F2FE).withAlpha(i.isEven ? 112 : 77),
//             Colors.transparent,
//           ],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ).createShader(streakRect)
//         ..strokeWidth = i.isEven ? 3.2 : 1.8
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round;

//       canvas.drawLine(
//         Offset(startX, startY),
//         Offset(endX, endY),
//         streakPaint,
//       );
//     }

//     final roadBand = Rect.fromLTWH(
//       0,
//       size.height * 0.72,
//       size.width,
//       size.height * 0.15,
//     );
//     paint.shader = const LinearGradient(
//       colors: [
//         Color(0x0022D3EE),
//         Color(0x4038BDF8),
//         Color(0x00F8FAFC),
//       ],
//       begin: Alignment.centerLeft,
//       end: Alignment.centerRight,
//     ).createShader(roadBand);
//     canvas.drawRect(roadBand, paint);

//     final dashPaint = Paint()..color = Colors.white.withAlpha(92);
//     const dashWidth = 52.0;
//     const dashGap = 32.0;
//     final dashOffset = (progress * 320) % (dashWidth + dashGap);
//     for (double x = -dashWidth;
//         x < size.width + dashWidth;
//         x += dashWidth + dashGap) {
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(
//           Rect.fromLTWH(x + dashOffset, size.height - 26, dashWidth, 3),
//           const Radius.circular(3),
//         ),
//         dashPaint,
//       );
//     }

//     final reflectionPath = Path()
//       ..moveTo(size.width * 0.62, 0)
//       ..lineTo(size.width * 0.82, 0)
//       ..lineTo(size.width * 0.57, size.height)
//       ..lineTo(size.width * 0.43, size.height)
//       ..close();
//     paint.shader = const LinearGradient(
//       colors: [
//         Color(0x30FFFFFF),
//         Color(0x00FFFFFF),
//       ],
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//     ).createShader(rect);
//     canvas.drawPath(reflectionPath, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _HeroShowcaseMotionPainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
