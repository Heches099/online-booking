import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/domain/entities/booked_ticket_record.dart';
import 'notification_service.dart';

class LocalTicketStorageService {
  static final LocalTicketStorageService _instance =
      LocalTicketStorageService._internal();

  factory LocalTicketStorageService() => _instance;

  LocalTicketStorageService._internal();

  final NotificationService _notificationService = NotificationService();
  static const String _ticketsPrefix = 'booked_ticket_records_';

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  String get _storageKey => '$_ticketsPrefix$_userId';

  Future<List<BookedTicketRecord>> loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final records = decoded
        .map((item) => BookedTicketRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
    records.sort((a, b) => b.travelDate.compareTo(a.travelDate));
    return records;
  }

  Future<void> saveTicket(BookedTicketRecord ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final tickets = await loadTickets();
    final index = tickets.indexWhere((item) => item.id == ticket.id);

    if (index == -1) {
      tickets.add(ticket.copyWith(userId: _userId));
    } else {
      tickets[index] = ticket.copyWith(userId: _userId);
    }

    tickets.sort((a, b) => b.departureDateTime.compareTo(a.departureDateTime));
    await prefs.setString(
      _storageKey,
      jsonEncode(tickets.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteTicket(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final tickets = await loadTickets();
    final target = tickets.where((item) => item.id == ticketId).toList();
    if (target.isNotEmpty && target.first.reminderEnabled) {
      await _notificationService.cancel(_notificationIdFor(ticketId));
    }
    tickets.removeWhere((item) => item.id == ticketId);
    await prefs.setString(
      _storageKey,
      jsonEncode(tickets.map((item) => item.toJson()).toList()),
    );
  }

  Future<BookedTicketRecord> toggleReminder(BookedTicketRecord ticket) async {
    if (ticket.reminderEnabled) {
      await _notificationService.cancel(_notificationIdFor(ticket.id));
      final updated = ticket.copyWith(
        reminderEnabled: false,
        clearReminderScheduledAt: true,
      );
      await saveTicket(updated);
      return updated;
    }

    final scheduledAt = _defaultReminderTime(ticket);
    await _notificationService.scheduleJourneyAlert(
      id: _notificationIdFor(ticket.id),
      title: 'Approaching destination',
      body:
          '${ticket.busName} is expected in ${ticket.to} at ${ticket.arrivalTime}.',
      scheduledDate: scheduledAt,
    );

    final updated = ticket.copyWith(
      reminderEnabled: true,
      reminderScheduledAt: scheduledAt,
    );
    await saveTicket(updated);
    return updated;
  }

  Future<BookedTicketRecord?> loadNextUpcomingTicket() async {
    final tickets = await loadTickets();
    final now = DateTime.now();
    final upcoming = tickets
        .where((ticket) => ticket.arrivalDateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.arrivalDateTime.compareTo(b.arrivalDateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  DateTime _defaultReminderTime(BookedTicketRecord ticket) {
    final planned = ticket.arrivalDateTime.subtract(const Duration(minutes: 30));
    if (planned.isAfter(DateTime.now())) {
      return planned;
    }
    return DateTime.now().add(const Duration(minutes: 1));
  }

  int _notificationIdFor(String ticketId) {
    var hash = 0;
    for (final code in ticketId.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }
}
