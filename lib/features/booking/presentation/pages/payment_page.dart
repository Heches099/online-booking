import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/bus.dart';
import 'abc_payment_webview_page.dart';
import 'ticket_confirmation_page.dart';
import '../../../../core/services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final Bus bus;
  final List<String> selectedSeats;
  final List<String> passengerNames;
  final String phone;
  final DateTime travelDate;

  const PaymentPage({
    super.key,
    required this.bus,
    required this.selectedSeats,
    required this.passengerNames,
    required this.phone,
    required this.travelDate,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentPhoneController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  static const Duration _paymentTimeout = Duration(minutes: 2);
  static const Duration _paymentStatusPollInterval = Duration(seconds: 5);
  String selectedMethod = 'M-Pesa';
  String selectedPaymentType = 'mobile'; // 'mobile' or 'bank'
  bool _isProcessing = false;
  bool _isPendingSheetOpen = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _paymentSub;
  Timer? _paymentTimeoutTimer;
  Timer? _paymentStatusPollTimer;
  String? _latestOrderId;
  bool _isSyncingPaymentStatus = false;

  bool get _isABCBooking => widget.bus.isABC;

  /// Mock yenye jina la ABC lakini bila IDs halisi: ZIMA checkout kabisa.
  /// Hairuhusiwi kwenda ZenoPay (hasara) wala ABC.
  bool get _isABCDemoBlocked => widget.bus.isABCDemo;

  String? get _abcSeatId {
    if (widget.selectedSeats.length != 1) return null;
    final label = widget.selectedSeats.single;
    final number = label
        .replaceFirst(RegExp(r'^Seat\s+', caseSensitive: false), '')
        .trim();
    return widget.bus.abcSeatIds[label] ?? widget.bus.abcSeatIds[number];
  }

  bool get _isABCMetadataReady =>
      widget.selectedSeats.length == 1 &&
      widget.bus.canCheckoutABC(_abcSeatId);

  bool get _canStartABCCheckout => _isABCBooking && _isABCMetadataReady;

  @override
  void initState() {
    super.initState();
    _paymentPhoneController.text = widget.phone;
    _paymentPhoneController.addListener(_syncPaymentMethodWithPhone);
    final autoMethod = _detectMobileMoneyMethod(widget.phone);
    if (autoMethod != null) {
      selectedMethod = autoMethod;
    }
  }

  @override
  void dispose() {
    _paymentPhoneController.removeListener(_syncPaymentMethodWithPhone);
    _paymentSub?.cancel();
    _paymentTimeoutTimer?.cancel();
    _paymentStatusPollTimer?.cancel();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> mobilePaymentMethods = [
    {
      'name': 'M-Pesa',
      'icon': Icons.phone_iphone,
      'color': Colors.red,
      'logo': 'assets/images/m_pesa.png',
    },
    {
      'name': 'Tigo Pesa',
      'label': 'Mixx by Yas',
      'icon': Icons.phone_android,
      'color': Colors.blue,
      'logo': 'assets/images/mixx-by-yas.png',
    },
    {
      'name': 'Airtel Money',
      'icon': Icons.phone_android,
      'color': Colors.red.shade900,
      'logo': 'assets/images/airtel-money.png',
    },
    {
      'name': 'Halopesa',
      'icon': Icons.phone_android,
      'color': Colors.orange,
      'logo': 'assets/images/halopesa.png',
    },
  ];

  final List<Map<String, dynamic>> bankPaymentMethods = [
    {
      'name': 'NMB Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'logo': 'assets/images/Nmb_logo.jpg',
    },
    {
      'name': 'CRDB Bank',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'logo': 'assets/images/Logo-crdb-bank-tanzania-clipart-PNG.avif',
    },
    {
      'name': 'Tanzania Bank',
      'icon': Icons.account_balance,
      'color': Colors.purple
    },
    {
      'name': 'Other Banks',
      'icon': Icons.account_balance,
      'color': Colors.orange
    },
  ];

  double _calculateTotal() {
    double total = 0;
    for (var seatStr in widget.selectedSeats) {
      int seatNum =
          int.tryParse(seatStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (seatNum == 53 || seatNum == 54) {
        total += widget.bus.price * 1.3;
      } else {
        total += widget.bus.price;
      }
    }
    return total;
  }

  void _syncPaymentMethodWithPhone() {
    if (!mounted || selectedPaymentType != 'mobile') return;
    final autoMethod = _detectMobileMoneyMethod(_paymentPhoneController.text);
    if (autoMethod == null || autoMethod == selectedMethod) return;
    setState(() => selectedMethod = autoMethod);
  }

  String? _detectMobileMoneyMethod(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    String local = digits;
    if (local.startsWith('255')) {
      local = local.substring(3);
    }
    if (local.startsWith('0')) {
      local = local.substring(1);
    }
    if (local.length < 2) return null;
    final prefix = local.substring(0, 2);

    if (['74', '75', '76'].contains(prefix)) return 'M-Pesa';
    if (['71', '65', '67'].contains(prefix)) return 'Tigo Pesa';
    if (['68', '69', '78'].contains(prefix)) return 'Airtel Money';
    if (['62'].contains(prefix)) return 'Halopesa';

    return null;
  }

  String _shortToken(String value, int maxLen) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return '';
    return cleaned.length <= maxLen ? cleaned : cleaned.substring(0, maxLen);
  }

  String _buildRouteToken() {
    if (widget.bus.route.isEmpty) return '';
    final origin = widget.bus.route.first;
    final dest = widget.bus.route.last;
    final originToken = _shortToken(origin, 3);
    final destToken = _shortToken(dest, 3);
    if (originToken.isEmpty && destToken.isEmpty) return '';
    return '$originToken$destToken';
  }

  String _buildPaymentReference(double amount) {
    final busToken = _shortToken(widget.bus.name, 8);
    final routeToken = _buildRouteToken();
    final dateToken = DateFormat('ddMM').format(widget.travelDate);
    final seatsToken = 'S${widget.selectedSeats.length}';
    final amountToken = 'T${amount.toStringAsFixed(0)}';
    final parts = [
      busToken,
      routeToken,
      dateToken,
      seatsToken,
      amountToken,
    ].where((part) => part.isNotEmpty).toList();
    final reference = parts.join('-');
    if (reference.length <= 40) return reference;
    return reference.substring(0, 40);
  }

  Future<void> _handleABCPayment() async {
    if (!_isABCMetadataReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'ABC checkout bado ni mock - inasubiri IDs halisi kutoka provider.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final session = await _paymentService.lockABCSeat(
        fromId: widget.bus.abcFromId!,
        toId: widget.bus.abcToId!,
        travelDate: widget.travelDate,
        seatId: _abcSeatId!,
        subId: widget.bus.operatorTripId!.trim(),
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (kIsWeb) {
        // Flutter Web haikubali kuweka Cookie header ya ABC (browser
        // same-origin policy). Fungua payment kwenye tab mpya kupitia
        // paymentUrl yenye ukey, kisha subiri pending_confirmation.
        final uri = Uri.tryParse(session.paymentUrl);
        if (uri == null) {
          throw StateError('ABC returned an invalid payment URL.');
        }
        final opened = await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          throw StateError(
              'Could not open the ABC payment page. Please allow popups and try again.');
        }
        if (!mounted) return;
        await _showABCWebPendingDialog(session.reservationId);
        return;
      }

      if (!session.canOpenInWebView) {
        throw StateError(
            'ABC did not return a usable payment session for this device.');
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ABCPaymentWebViewPage(
            session: session,
            seatLabel: widget.selectedSeats.single,
            onCheckoutReturn: _paymentService.recordABCCheckoutReturn,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final message = error.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Baada ya kulipa ABC kwenye tab mpya, bonyeza Thibitisha.
  /// ABC haina webhook: tunaweka pending_confirmation, si booked.
  Future<void> _showABCWebPendingDialog(String reservationId) {
    bool confirming = false;
    final messenger = ScaffoldMessenger.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Kamilisha malipo ABC'),
          content: const Text(
            'Umefunguliwa ukurasa wa malipo wa ABC kwenye tab mpya.\n\n'
            'Baada ya kulipa ABC, bonyeza Thibitisha. Tiketi itabaki '
            'pending_confirmation hadi ABC ithibitishe malipo.',
          ),
          actions: [
            TextButton(
              onPressed: confirming
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('GHAIRI'),
            ),
            ElevatedButton(
              onPressed: confirming
                  ? null
                  : () async {
                      setDialogState(() => confirming = true);
                      try {
                        await _paymentService
                            .recordABCCheckoutReturn(reservationId);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Asante! Kurudi kwako kumerekodiwa kama pending_confirmation. Tutathibitisha tiketi ABC ikijibu.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => confirming = false);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Imeshindikana kurekodi kurudi: ${e.toString().replaceFirst('Bad state: ', '')}'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: confirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('NIMELIPA — THIBITISHA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_isABCDemoBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'ABC checkout bado ni mock - inasubiri IDs halisi kutoka provider.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_isABCBooking) {
      await _handleABCPayment();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final double totalAmount = _calculateTotal();
    final String paymentReference = _buildPaymentReference(totalAmount);
    final user = Supabase.instance.client.auth.currentUser;
    // Always create an orderId so we can reserve seats regardless of method
    final String orderId = "ZEN-${DateTime.now().millisecondsSinceEpoch}";
    _latestOrderId = orderId;

    try {
      // Reserve seats on the server before initiating payment
      final Map<String, dynamic> reserveResp =
          await _paymentService.reserveSeats(
        orderId: orderId,
        busId: widget.bus.id,
        travelDate: widget.travelDate,
        seats: widget.selectedSeats,
      );

      final bool reserved = reserveResp['success'] == true;
      if (!reserved) {
        final String message = reserveResp['message']?.toString() ??
            'Selected seats are no longer available.';
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final PaymentInitResult result = selectedPaymentType == 'mobile'
          ? await _paymentService.initiateZenopayPayment(
              phoneNumber: _paymentPhoneController.text,
              amount: totalAmount,
              email: user?.email ?? "traveler@heches.com",
              fullName: widget.passengerNames[0],
              orderId: orderId,
              paymentReference: paymentReference,
            )
          : await _paymentService.initiateBank(
              bankName: selectedMethod,
              amount: totalAmount,
              email: user?.email ?? "traveler@heches.com",
              fullName: widget.passengerNames[0],
              orderId: orderId,
            );

      final String trackedOrderId = result.orderId ?? orderId;
      _latestOrderId = trackedOrderId;

      if (mounted) {
        setState(() => _isProcessing = false);
        if (result.isSuccess) {
          _showSuccessAndGenerateTicket(trackedOrderId);
        } else if (result.isPending) {
          _showPendingSheet(result.message);
          _listenForPaymentStatus(trackedOrderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message ??
                    "Payment unsuccessful or cancelled. Check your balance/PIN.",
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gateway Error: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _listenForPaymentStatus(String orderId) {
    _paymentSub?.cancel();
    _paymentTimeoutTimer?.cancel();
    _paymentStatusPollTimer?.cancel();
    _startPaymentTimeout(orderId);
    _startPaymentStatusPolling(orderId);
    _paymentSub = Supabase.instance.client
        .from('payments')
        .stream(primaryKey: ['orderId'])
        .eq('orderId', orderId)
        .listen((rows) {
      if (rows.isEmpty) return;
      final data = rows.first;

      final String status = (data['status'] ?? '').toString().toLowerCase();
      if (status.isEmpty) return;

      if (status == 'completed') {
        _paymentTimeoutTimer?.cancel();
        _paymentStatusPollTimer?.cancel();
        _paymentSub?.cancel();
        _closePendingSheetIfOpen();
        if (mounted) _showSuccessAndGenerateTicket(orderId);
        return;
      }

      if (status == 'cancelled' ||
          status == 'canceled' ||
          status == 'timeout' ||
          status == 'expired') {
        _paymentTimeoutTimer?.cancel();
        _paymentStatusPollTimer?.cancel();
        _paymentSub?.cancel();
        _closePendingSheetIfOpen();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Payment cancelled on your phone or timed out. Please try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (status == 'failed' || status == 'error') {
        _paymentTimeoutTimer?.cancel();
        _paymentStatusPollTimer?.cancel();
        _paymentSub?.cancel();
        _closePendingSheetIfOpen();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Payment failed or cancelled. Please try again or use a different number."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }, onError: (_) {
      _paymentTimeoutTimer?.cancel();
      _paymentStatusPollTimer?.cancel();
      _paymentSub?.cancel();
      _closePendingSheetIfOpen();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment status check failed. Please try again."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _startPaymentTimeout(String orderId) {
    _paymentTimeoutTimer?.cancel();
    _paymentTimeoutTimer = Timer(_paymentTimeout, () async {
      final bool didCancel =
          await _cancelPendingPayment(orderId, reason: 'timeout');
      if (!didCancel) return;
      if (!mounted) return;
      _paymentStatusPollTimer?.cancel();
      _paymentSub?.cancel();
      _closePendingSheetIfOpen();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Payment timed out. Please try again or use another number."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _startPaymentStatusPolling(String orderId) {
    _paymentStatusPollTimer?.cancel();
    _pollPaymentStatus(orderId);
    if (PaymentService.backendBaseUrl.isEmpty) return;

    _paymentStatusPollTimer = Timer.periodic(_paymentStatusPollInterval, (_) {
      _pollPaymentStatus(orderId);
    });
  }

  Future<void> _pollPaymentStatus(String orderId) async {
    if (_isSyncingPaymentStatus || PaymentService.backendBaseUrl.isEmpty) {
      return;
    }

    _isSyncingPaymentStatus = true;
    try {
      await _paymentService.syncPendingPaymentStatus(orderId);
    } finally {
      _isSyncingPaymentStatus = false;
    }
  }

  Future<bool> _cancelPendingPayment(String orderId,
      {required String reason}) async {
    try {
      final didCancel =
          await _paymentService.cancelOrder(orderId, reason: reason);
      return didCancel;
    } catch (_) {
      return false;
    }
  }

  void _showPendingSheet(String? message) {
    _isPendingSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              "Awaiting Payment Confirmation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message ??
                  "A payment request was sent to your phone. Please approve it to continue.",
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            _buildPaymentSummaryCard(_calculateTotal()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  _paymentSub?.cancel();
                  _paymentTimeoutTimer?.cancel();
                  _paymentStatusPollTimer?.cancel();
                  _closePendingSheetIfOpen();
                  final orderId = _latestOrderId;
                  if (orderId != null) {
                    final didCancel = await _cancelPendingPayment(orderId,
                        reason: 'user_cancelled');
                    if (didCancel) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Payment cancelled."),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _isPendingSheetOpen = false);
  }

  void _closePendingSheetIfOpen() {
    if (_isPendingSheetOpen && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSuccessAndGenerateTicket(String? orderId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 60),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Transaction Secured!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              "Payment of TZS ${_calculateTotal().toStringAsFixed(0)} received. Your royal e-ticket is ready.",
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.premiumShadow,
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketConfirmationPage(
                        bus: widget.bus,
                        selectedSeats: widget.selectedSeats,
                        passengerName: widget.passengerNames[0],
                        travelDate: widget.travelDate,
                        orderId: orderId ?? _latestOrderId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text("VIEW MY TICKET",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = _calculateTotal();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("PAYMENT",
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isABCBooking || _isABCDemoBlocked) ...[
                _buildSectionHeader('ABC DIRECT CHECKOUT'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.bus.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Seat: ${widget.selectedSeats.join(', ')}'),
                      Text(
                          'Travel date: ${_formatTravelDate(widget.travelDate)}'),
                      const SizedBox(height: 12),
                      const Text(
                        'ABC will confirm the fare and collect payment on its secure payment page.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_isABCDemoBlocked) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'ABC checkout bado ni mock - inasubiri IDs halisi kutoka provider.',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ] else if (!_isABCMetadataReady) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'ABC booking is unavailable for this bus. Live route, trip, and seat IDs are required.',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ] else if (kIsWeb) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Malipo yatafunguliwa kwenye tab mpya ya ABC. Baada ya kulipa, bonyeza Thibitisha.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ] else ...[
                FadeInDown(child: _buildAmountCard(totalAmount)),
                const SizedBox(height: 32),
                _buildSectionHeader('PAYMENT METHOD'),
                const SizedBox(height: 16),
                _buildPaymentTypeSelector(),
                const SizedBox(height: 32),
                if (selectedPaymentType == 'mobile') ...[
                  _buildSectionHeader('SELECT MOBILE MONEY'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: mobilePaymentMethods
                          .map((method) => _buildSquareMethodTile(method))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('PAYMENT NUMBER'),
                  const SizedBox(height: 16),
                  _buildPhoneField(),
                  const SizedBox(height: 12),
                  const Text(
                    'You will be redirected to authorize your mobile money payment.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  _buildSectionHeader('SELECT BANK'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: bankPaymentMethods
                          .map((method) => _buildSquareMethodTile(method))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBankTransferInfo(),
                ],
              ],
              const SizedBox(height: 40),
              FadeInUp(child: _buildPayButton(totalAmount)),
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _isABCBooking || _isABCDemoBlocked
                          ? 'PAYMENT PROCESSED BY ABC'
                          : 'SECURED BY ZENOPAY',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5),
    );
  }

  String _formatTravelDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(double amount) {
    final seats = widget.selectedSeats.join(", ");
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textMuted.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow("Amount", "TZS ${amount.toStringAsFixed(0)}"),
          const SizedBox(height: 6),
          _summaryRow("Bus", widget.bus.name),
          const SizedBox(height: 6),
          _summaryRow("Seats", seats.isEmpty ? "-" : seats),
          const SizedBox(height: 6),
          _summaryRow("Travel Date", _formatTravelDate(widget.travelDate)),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentTypeButton('mobile', 'Mobile Money'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPaymentTypeButton('bank', 'Bank Transfer'),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeButton(String type, String label) {
    bool isSelected = selectedPaymentType == type;
    return GestureDetector(
      onTap: () => setState(() {
        selectedPaymentType = type;
        if (type == 'mobile') selectedMethod = 'M-Pesa';
        if (type == 'bank') selectedMethod = 'NMB Bank';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textMuted.withAlpha(77),
            width: 2,
          ),
          boxShadow: isSelected ? AppColors.softShadow : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Bank Transfer Instructions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'be redirected to complete your bank transfer. Please ensure you have sufficient funds in your selected bank account.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL PAYABLE",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text("TZS ${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(10)),
                child: Text("${widget.selectedSeats.length} SEATS",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(widget.bus.name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareMethodTile(Map<String, dynamic> method) {
    bool isSelected = selectedMethod == method['name'];
    final logoPath = method['logo'] as String?;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2),
          boxShadow: isSelected ? AppColors.softShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 42,
              child: logoPath == null
                  ? Icon(
                      method['icon'],
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 28,
                    )
                  : Image.asset(
                      logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        method['icon'],
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(method['label'] ?? method['name'],
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: _paymentPhoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1),
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
          hintText: "0xxx xxx xxx",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.length < 10) {
            return "Valid number required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPayButton(double amount) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.premiumShadow,
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ||
                _isABCDemoBlocked ||
                (_isABCBooking && !_canStartABCCheckout)
            ? null
            : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isABCBooking || _isABCDemoBlocked
                    ? "CONTINUE TO ABC PAYMENT"
                    : "PROCEED TO PAY",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1)),
      ),
    );
  }
}
