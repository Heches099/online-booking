class Ticket {
  final String id;
  final String userId;
  final String busId;
  final String busName;
  final String from;
  final String to;
  final DateTime date;
  final String time;
  final List<String> seatNumbers;
  final String status; // Upcoming, Completed, Cancelled
  final String qrCode;
  final double totalPrice;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.busId,
    required this.busName,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.seatNumbers,
    required this.status,
    required this.qrCode,
    required this.totalPrice,
    required this.createdAt,
  });

  factory Ticket.fromFirestore(Map<String, dynamic> data) {
    return Ticket(
      id: data['id']?.toString() ?? '',
      userId: data['userId'] ?? '',
      busId: data['busId'] ?? '',
      busName: data['busName'] ?? '',
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      date: _readDate(data['date']),
      time: data['time'] ?? '',
      seatNumbers: List<String>.from(data['seatNumbers'] ?? []),
      status: data['status'] ?? 'Upcoming',
      qrCode: data['qrCode'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      createdAt: _readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'busId': busId,
      'busName': busName,
      'from': from,
      'to': to,
      'date': date.toIso8601String(),
      'time': time,
      'seatNumbers': seatNumbers,
      'status': status,
      'qrCode': qrCode,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
