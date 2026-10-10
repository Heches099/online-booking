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
import 'history.dart';
import 'profile.dart';
import 'track.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _homeScrollController = ScrollController();
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
    _homeScrollController.dispose();
    super.dispose();
  }

  void _scrollToBooking() {
    if (!_homeScrollController.hasClients) return;
    _homeScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _openShortcutPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _showHomeShortcuts() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2D2D2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quick access',
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              _shortcutTile(
                icon: Icons.search_rounded,
                title: 'Book a bus',
                subtitle: 'Choose a route and travel date',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scrollToBooking();
                },
              ),
              _shortcutTile(
                icon: Icons.confirmation_num_outlined,
                title: 'My tickets',
                subtitle: 'View bookings and trip history',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openShortcutPage(const HistoryPage());
                },
              ),
              _shortcutTile(
                icon: Icons.location_on_outlined,
                title: 'Track my trip',
                subtitle: 'Open live journey tracking',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openShortcutPage(const TrackPage());
                },
              ),
              _shortcutTile(
                icon: Icons.notifications_active_outlined,
                title: 'Journey alerts',
                subtitle: 'Manage reminder times and sounds',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotificationSettings();
                },
              ),
              _shortcutTile(
                icon: Icons.person_outline_rounded,
                title: 'My account',
                subtitle: 'Profile and travel preferences',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openShortcutPage(const ProfilePage());
                },
              ),
              _shortcutTile(
                icon: Icons.help_outline_rounded,
                title: 'Booking help',
                subtitle: 'Quick answers about using the app',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBookingHelp();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF098E5F), size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  void _showBookingHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking help',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 18),
              _HelpAnswer(
                question: 'How do I book a trip?',
                answer:
                    'Select your departure, destination, and travel date. Choose a bus, then continue to seat selection and checkout.',
              ),
              SizedBox(height: 14),
              _HelpAnswer(
                question: 'Where can I find my ticket?',
                answer:
                    'Open My tickets from Quick access or the Tickets tab to view saved bookings and trip details.',
              ),
              SizedBox(height: 14),
              _HelpAnswer(
                question: 'How do journey reminders work?',
                answer:
                    'Open Journey alerts, choose reminder times and a sound, then activate alerts for your next upcoming trip.',
              ),
            ],
          ),
        ),
      ),
    );
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
      backgroundColor: const Color(0xFFF0F7F4),
      body: SingleChildScrollView(
        controller: _homeScrollController,
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon/logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    cacheWidth: 126,
                    semanticLabel: 'NextGen bus booking logo',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'HECHES ONLINE BOOKING',
                    style: TextStyle(
                      color: Color(0xFF191919),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Journey alerts',
                  onPressed: _showNotificationSettings,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF098E5F),
                    size: 23,
                  ),
                ),
                IconButton(
                  tooltip: 'Quick access menu',
                  onPressed: _showHomeShortcuts,
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF098E5F),
                    size: 27,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Book Bus Tickets',
              style: TextStyle(
                color: Color(0xFF191919),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          FadeInUp(child: const SearchCard()),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Popular Routes',
            'VIEW ALL',
            _showAllRoutes,
          ),
          const SizedBox(height: 12),
          _buildMajesticRoutes(),
          const SizedBox(height: 24),
          _buildLuxuryPromo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action,
    VoidCallback onActionTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextButton.icon(
          onPressed: onActionTap,
          icon: const Icon(Icons.arrow_forward_rounded, size: 15),
          label: Text(action),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF098E5F),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMajesticRoutes() {
    final routes = _featuredRoutes();

    return SizedBox(
      height: 256,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final route = routes[index];
          return _AnimatedRouteCard(
            name: route.label,
            price: route.priceLabel,
            imagePath: route.imagePath,
            onTap: () => _openRoute(route),
          );
        },
      ),
    );
  }

  List<_FeaturedRoute> _featuredRoutes() {
    return [
      _FeaturedRoute(
        label: 'DAR - ARUSHA',
        from: 'Dar es Salaam',
        to: 'Arusha',
        price: RoutePricing.priceFor('Dar es Salaam', 'Arusha'),
        imagePath: 'assets/images/machame.png',
      ),
      _FeaturedRoute(
        label: 'DAR - MBEYA',
        from: 'Dar es Salaam',
        to: 'Mbeya',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mbeya'),
        imagePath: 'assets/images/new_force.jpg',
      ),
      _FeaturedRoute(
        label: 'DAR - DODOMA',
        from: 'Dar es Salaam',
        to: 'Dodoma',
        price: RoutePricing.priceFor('Dar es Salaam', 'Dodoma'),
        imagePath: 'assets/images/shabiby.png',
      ),
      _FeaturedRoute(
        label: 'DAR - SINGIDA',
        from: 'Dar es Salaam',
        to: 'Singida',
        price: RoutePricing.priceFor('Dar es Salaam', 'Singida'),
        imagePath: 'assets/images/abc_upper_class.webp',
      ),
      _FeaturedRoute(
        label: 'DAR - MWANZA',
        from: 'Dar es Salaam',
        to: 'Mwanza',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mwanza'),
        imagePath: 'assets/images/BM_coach.jpeg',
      ),
      _FeaturedRoute(
        label: 'DAR - TANGA',
        from: 'Dar es Salaam',
        to: 'Tanga',
        price: RoutePricing.priceFor('Dar es Salaam', 'Tanga'),
        imagePath: 'assets/images/Ester_luxury.png',
      ),
      _FeaturedRoute(
        label: 'DAR - MOROGORO',
        from: 'Dar es Salaam',
        to: 'Morogoro',
        price: RoutePricing.priceFor('Dar es Salaam', 'Morogoro'),
        imagePath: 'assets/images/abood.png',
      ),
      _FeaturedRoute(
        label: 'DAR - Mtwara',
        from: 'Dar es Salaam',
        to: 'Mtwara',
        price: RoutePricing.priceFor('Dar es Salaam', 'Mtwara'),
        imagePath: 'assets/images/buti_la_zungu.png',
      ),
      _FeaturedRoute(
        label: 'DAR - Kahama',
        from: 'Dar es Salaam',
        to: 'Kahama',
        price: RoutePricing.priceFor('Dar es Salaam', 'Kahama'),
        imagePath: 'assets/images/katarama.jpeg',
      ),
    ];
  }

  void _openRoute(_FeaturedRoute route) {
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
  }

  void _showAllRoutes() {
    final routes = _featuredRoutes();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Popular routes',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close routes',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            route.imagePath,
                            width: 66,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          '${route.from} to ${route.to}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text('From ${route.priceLabel}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openRoute(route);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryPromo() {
    return Container(
      width: double.infinity,
      height: 142,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: 0,
            bottom: 0,
            width: 190,
            child: Image.asset(
              'assets/images/abc_upper.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFECECEC),
                    const Color(0xFFECECEC).withAlpha(240),
                    const Color(0xFFECECEC).withAlpha(0),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 105, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Travel\nStarts Here',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Safe. Reliable. Convenient.',
                  maxLines: 2,
                  style: TextStyle(
                    // color: Color(0xFF5F5F5F),
                    color: Color.fromARGB(255, 73, 153, 238),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
  final String imagePath;

  const _FeaturedRoute({
    required this.label,
    required this.from,
    required this.to,
    required this.price,
    required this.imagePath,
  });

  String get priceLabel => 'TZS ${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      )}';
}

class _AnimatedRouteCard extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;
  final VoidCallback onTap;

  const _AnimatedRouteCard({
    required this.name,
    required this.price,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_AnimatedRouteCard> createState() => _AnimatedRouteCardState();
}

class _AnimatedRouteCardState extends State<_AnimatedRouteCard> {
  bool _isPressed = false;

  Color get _normalBorderColor => const Color(0xFFE3E3E3);
  Color get _pressedBorderColor => const Color(0xFF098E5F);

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
          width: 232,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: SizedBox(
                  height: 142,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        cacheWidth: 700,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x88000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(235),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        color: Color(0xFF202020),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        color: Color(0xFF098E5F),
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

class _HelpAnswer extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpAnswer({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
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
