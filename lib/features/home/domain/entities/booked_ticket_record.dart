import 'package:intl/intl.dart';

class BookedTicketRecord {
  final String id;
  final String userId;
  final String busId;
  final String busName;
  final String busType;
  final String from;
  final String to;
  final DateTime travelDate;
  final String departureTime;
  final String arrivalTime;
  final List<String> seatNumbers;
  final String passengerName;
  final double totalPrice;
  final String status;
  final String reference;
  final bool reminderEnabled;
  final DateTime? reminderScheduledAt;
  final DateTime createdAt;

  const BookedTicketRecord({
    required this.id,
    required this.userId,
    required this.busId,
    required this.busName,
    required this.busType,
    required this.from,
    required this.to,
    required this.travelDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.seatNumbers,
    required this.passengerName,
    required this.totalPrice,
    required this.status,
    required this.reference,
    required this.reminderEnabled,
    required this.reminderScheduledAt,
    required this.createdAt,
  });

  BookedTicketRecord copyWith({
    String? id,
    String? userId,
    String? busId,
    String? busName,
    String? busType,
    String? from,
    String? to,
    DateTime? travelDate,
    String? departureTime,
    String? arrivalTime,
    List<String>? seatNumbers,
    String? passengerName,
    double? totalPrice,
    String? status,
    String? reference,
    bool? reminderEnabled,
    DateTime? reminderScheduledAt,
    bool clearReminderScheduledAt = false,
    DateTime? createdAt,
  }) {
    return BookedTicketRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      busType: busType ?? this.busType,
      from: from ?? this.from,
      to: to ?? this.to,
      travelDate: travelDate ?? this.travelDate,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      passengerName: passengerName ?? this.passengerName,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderScheduledAt: clearReminderScheduledAt
          ? null
          : reminderScheduledAt ?? this.reminderScheduledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookedTicketRecord.fromJson(Map<String, dynamic> json) {
    return BookedTicketRecord(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? 'guest',
      busId: json['busId']?.toString() ?? '',
      busName: json['busName']?.toString() ?? '',
      busType: json['busType']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      travelDate: DateTime.tryParse(json['travelDate']?.toString() ?? '') ??
          DateTime.now(),
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      seatNumbers: List<String>.from(json['seatNumbers'] as List? ?? const []),
      passengerName: json['passengerName']?.toString() ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'Upcoming',
      reference: json['reference']?.toString() ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderScheduledAt:
          DateTime.tryParse(json['reminderScheduledAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'busId': busId,
      'busName': busName,
      'busType': busType,
      'from': from,
      'to': to,
      'travelDate': travelDate.toIso8601String(),
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'seatNumbers': seatNumbers,
      'passengerName': passengerName,
      'totalPrice': totalPrice,
      'status': status,
      'reference': reference,
      'reminderEnabled': reminderEnabled,
      'reminderScheduledAt': reminderScheduledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DateTime get departureDateTime {
    return _resolveTimeOnTravelDate(departureTime, fallbackHour: 8);
  }

  DateTime get arrivalDateTime {
    final arrival = _resolveTimeOnTravelDate(
      arrivalTime,
      fallbackHour: departureDateTime.hour + 1,
    );

    if (arrival.isAfter(departureDateTime)) {
      return arrival;
    }

    return arrival.add(const Duration(days: 1));
  }

  String get currentStatus {
    if (status == 'Cancelled') {
      return status;
    }
    return arrivalDateTime.isBefore(DateTime.now()) ? 'Completed' : 'Upcoming';
  }

  String get routeLabel => '$from -> $to';

  DateTime _resolveTimeOnTravelDate(
    String rawTime, {
    required int fallbackHour,
  }) {
    try {
      final parsedTime = DateFormat('hh:mm a').parse(rawTime);
      return DateTime(
        travelDate.year,
        travelDate.month,
        travelDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      final normalizedHour = fallbackHour.clamp(0, 23);
      return DateTime(
        travelDate.year,
        travelDate.month,
        travelDate.day,
        normalizedHour,
      );
    }
  }
}
