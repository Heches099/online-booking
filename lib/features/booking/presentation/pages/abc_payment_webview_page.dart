import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_colors.dart';

class ABCPaymentWebViewPage extends StatefulWidget {
  final ABCCheckoutSession session;
  final String seatLabel;
  final Future<void> Function(String reservationId) onCheckoutReturn;

  const ABCPaymentWebViewPage({
    super.key,
    required this.session,
    required this.seatLabel,
    required this.onCheckoutReturn,
  });

  @override
  State<ABCPaymentWebViewPage> createState() => _ABCPaymentWebViewPageState();
}

class _ABCPaymentWebViewPageState extends State<ABCPaymentWebViewPage> {
  late final Future<void> _cookiesReady = _installCookies();
  bool _isRecordingReturn = false;
  bool _returnRecorded = false;
  String? _returnMessage;

  Future<void> _installCookies() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'ABC payment cookies require the Android or iOS app.',
      );
    }

    final paymentUri = WebUri(widget.session.paymentUrl);
    final cookieManager = CookieManager.instance();
    for (final cookie in widget.session.cookies) {
      final name = cookie['name']?.toString();
      final value = cookie['value']?.toString();
      if (name == null || value == null) continue;

      final domain = cookie['domain']?.toString();
      final isHostOnly = cookie['hostOnly'] == true;
      final wasSet = await cookieManager.setCookie(
        url: paymentUri,
        name: name,
        value: value,
        domain: isHostOnly || domain == null || domain.isEmpty ? null : domain,
        path: cookie['path']?.toString() ?? '/',
        isSecure: cookie['secure'] == true,
        isHttpOnly: cookie['httpOnly'] == true,
      );
      if (!wasSet) {
        throw StateError('Could not install the ABC payment session.');
      }
    }
  }

  Future<void> _handleLoadedUrl(WebUri? url) async {
    if (url == null || _returnRecorded || _isRecordingReturn) return;
    final uri = Uri.tryParse(url.toString());
    if (uri == null || uri.host != 'www.abcupperclass.co.tz') return;
    final returnPath = RegExp(r'(^|/)(ticket|success|confirmation)(/|$)')
        .hasMatch(uri.path.toLowerCase());
    if (!returnPath) return;

    setState(() {
      _isRecordingReturn = true;
      _returnMessage =
          'Umerudi kutoka ABC. Uthibitisho wa tiketi unasubiri ABC.';
    });
    try {
      await widget.onCheckoutReturn(widget.session.reservationId);
      _returnRecorded = true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _returnMessage =
              'Kurudi kwa ABC kumeonekana, lakini haikuweza kurekodiwa. Tiketi bado haijathibitishwa.';
        });
      }
    } finally {
      if (mounted) setState(() => _isRecordingReturn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Malipo · ABC · ${widget.seatLabel}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _cookiesReady,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Malipo ya ABC hayawezi kufunguliwa kwa session salama. '
                  '${snapshot.error is UnsupportedError ? 'Tumia app ya Android au iOS.' : 'Jaribu tena baadaye.'}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              if (_returnMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFFFFF4D6),
                  child: Text(
                    _returnMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest:
                      URLRequest(url: WebUri(widget.session.paymentUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                  ),
                  onLoadStop: (controller, url) => _handleLoadedUrl(url),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
