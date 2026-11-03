import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // add to pubspec.yaml

import '../../../../core/services/local_ticket_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booked_ticket_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final LocalTicketStorageService _ticketStorageService =
      LocalTicketStorageService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<BookedTicketRecord> _tickets = [];
  String _selectedStatus = 'All';
  String _selectedBusType = 'All';
  String _selectedTimeWindow = 'All';
  DateTime? _selectedDate;

  static const List<String> _statusFilters = [
    'All',
    'Upcoming',
    'Completed',
    'Reminder On',
  ];

  static const List<String> _timeFilters = [
    'All',
    'Morning',
    'Afternoon',
    'Evening',
  ];

  // Animation controller for filter container (optional)
  late AnimationController _filterExpandController;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _searchController.addListener(() => setState(() {}));
    _filterExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterExpandController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterExpandController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final tickets = await _ticketStorageService.loadTickets();
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  Future<void> _pickDateFilter() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
  }

  Future<void> _toggleReminder(BookedTicketRecord ticket) async {
    if (!ticket.reminderEnabled) {
      final permissionsGranted =
          await NotificationService().ensurePermissions();
      if (!permissionsGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow notifications to turn on trip reminders.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    await _ticketStorageService.toggleReminder(ticket);
    await _loadTickets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ticket.reminderEnabled
              ? 'Reminder removed for ${ticket.busName}.'
              : 'Reminder scheduled for ${ticket.busName}.',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteTicket(BookedTicketRecord ticket) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete ticket'),
            content: Text(
              'Remove ${ticket.busName} from ${ticket.from} to ${ticket.to} from your history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await _ticketStorageService.deleteTicket(ticket.id);
    await _loadTickets();
  }

  List<BookedTicketRecord> get _filteredTickets {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _tickets.where((ticket) {
      final matchesQuery = query.isEmpty ||
          ticket.busName.toLowerCase().contains(query) ||
          ticket.routeLabel.toLowerCase().contains(query) ||
          ticket.passengerName.toLowerCase().contains(query) ||
          ticket.reference.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Reminder On' && ticket.reminderEnabled) ||
          ticket.currentStatus == _selectedStatus;
      final matchesBusType =
          _selectedBusType == 'All' || ticket.busType == _selectedBusType;
      final matchesTime = _selectedTimeWindow == 'All' ||
          _timeWindowFor(ticket) == _selectedTimeWindow;
      final matchesDate = _selectedDate == null ||
          _isSameDay(ticket.travelDate, _selectedDate!);
      return matchesQuery &&
          matchesStatus &&
          matchesBusType &&
          matchesTime &&
          matchesDate;
    }).toList();

    filtered.sort((a, b) {
      final aUpcoming = a.departureDateTime.isAfter(DateTime.now());
      final bUpcoming = b.departureDateTime.isAfter(DateTime.now());
      if (aUpcoming != bUpcoming) return aUpcoming ? -1 : 1;
      if (aUpcoming && bUpcoming) {
        return a.departureDateTime.compareTo(b.departureDateTime);
      }
      return b.departureDateTime.compareTo(a.departureDateTime);
    });
    return filtered;
  }

  List<String> get _busTypes {
    final values = _tickets.map((ticket) => ticket.busType).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  int get _upcomingCount =>
      _tickets.where((ticket) => ticket.currentStatus == 'Upcoming').length;

  int get _reminderCount =>
      _tickets.where((ticket) => ticket.reminderEnabled).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const ShimmerLoading()
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 150,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  transform: Matrix4.translationValues(0, 0, 0),
                                  child: const Text(
                                    'TICKETS & HISTORY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Search, filter, remind, and clean up your booked trips.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildSummaryCard(
                                label: 'Total tickets',
                                value: _tickets.length.toString(),
                                icon: Icons.confirmation_number_rounded,
                                index: 0,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSummaryCard(
                                label: 'Upcoming',
                                value: _upcomingCount.toString(),
                                icon: Icons.upcoming_rounded,
                                index: 1,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSummaryCard(
                                label: 'Reminders',
                                value: _reminderCount.toString(),
                                icon: Icons.notifications_active_rounded,
                                index: 2,
                              )),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 18),
                          _buildFilters(),
                          const SizedBox(height: 18),
                          AnimatedCrossFade(
                            firstChild: _buildEmptyState(),
                            secondChild: const SizedBox.shrink(),
                            crossFadeState: _filteredTickets.isEmpty
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 400),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_filteredTickets.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final ticket = _filteredTickets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _AnimatedTicketCard(
                                ticket: ticket,
                                onToggleReminder: _toggleReminder,
                                onDelete: _deleteTicket,
                                animationIndex: index,
                              ),
                            );
                          },
                          childCount: _filteredTickets.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required int index,
  }) {
    return Hero(
      tag: 'summary_$index',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by bus, route, passenger, or reference',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                    if (_showFilters) {
                      _filterExpandController.forward();
                    } else {
                      _filterExpandController.reverse();
                    }
                  });
                },
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _filterExpandController,
                ),
                tooltip: 'Toggle filters',
              ),
            ],
          ),
          SizeTransition(
            sizeFactor: _filterExpandController,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Bus category',
                  value: _selectedBusType,
                  items: _busTypes,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedBusType = value);
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdownRow(
                  label: 'Time',
                  value: _selectedTimeWindow,
                  items: _timeFilters,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedTimeWindow = value);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusFilters.map((filter) {
                    final isSelected = _selectedStatus == filter;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(isSelected ? 1.05 : 1.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = filter),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateFilter,
                        icon:
                            const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          _selectedDate == null
                              ? 'Choose date'
                              : DateFormat('dd MMM yyyy')
                                  .format(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: () => setState(() => _selectedDate = null),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                onChanged: onChanged,
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.travel_explore_rounded,
              size: 54, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No tickets match these filters yet.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Completed and upcoming bookings will appear here after payment confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _timeWindowFor(BookedTicketRecord ticket) {
    final hour = ticket.departureDateTime.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

// Animated ticket card with fade + slide on appear
class _AnimatedTicketCard extends StatefulWidget {
  final BookedTicketRecord ticket;
  final void Function(BookedTicketRecord) onToggleReminder;
  final void Function(BookedTicketRecord) onDelete;
  final int animationIndex;

  const _AnimatedTicketCard({
    required this.ticket,
    required this.onToggleReminder,
    required this.onDelete,
    required this.animationIndex,
  });

  @override
  State<_AnimatedTicketCard> createState() => _AnimatedTicketCardState();
}

class _AnimatedTicketCardState extends State<_AnimatedTicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Start animation after a short delay based on index
    Future.delayed(Duration(milliseconds: 50 * widget.animationIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _TicketCard(
          ticket: widget.ticket,
          onToggleReminder: widget.onToggleReminder,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }
}

// Core ticket card widget (separate for better animation control)
class _TicketCard extends StatefulWidget {
  final BookedTicketRecord ticket;
  final void Function(BookedTicketRecord) onToggleReminder;
  final void Function(BookedTicketRecord) onDelete;

  const _TicketCard({
    required this.ticket,
    required this.onToggleReminder,
    required this.onDelete,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.ticket.currentStatus == 'Upcoming') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final status = ticket.currentStatus;
    final scheduledReminder = ticket.reminderScheduledAt == null
        ? null
        : DateFormat('dd MMM, hh:mm a').format(ticket.reminderScheduledAt!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.busName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.busType,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ticket.routeLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                '${DateFormat('dd MMM yyyy').format(ticket.travelDate)} • ${ticket.departureTime}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_seat_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seats ${ticket.seatNumbers.join(', ')} • ${ticket.passengerName}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reference ${ticket.reference}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                'TZS ${ticket.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (ticket.reminderEnabled && scheduledReminder != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reminder stored for $scheduledReminder',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onToggleReminder(ticket),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          RotationTransition(turns: anim, child: child),
                      child: Icon(
                        ticket.reminderEnabled
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                        key: ValueKey(ticket.reminderEnabled),
                        size: 18,
                      ),
                    ),
                    label: Text(
                      ticket.reminderEnabled
                          ? 'Remove reminder'
                          : 'Save reminder',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => widget.onDelete(ticket),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isUpcoming = status == 'Upcoming';
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isUpcoming ? _pulseController.value : 0.0;
        final scale = 1.0 + pulseValue * 0.05;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppColors.primary.withAlpha(18)
                  : AppColors.success.withAlpha(18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isUpcoming ? AppColors.primary : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Shimmer loading widget
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }
}
