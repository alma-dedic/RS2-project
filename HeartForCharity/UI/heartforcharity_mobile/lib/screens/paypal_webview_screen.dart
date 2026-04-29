import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebViewScreen extends StatefulWidget {
  final String approvalUrl;
  final String orderId;
  final DonationProvider provider;
  final VoidCallback onSuccess;
  final VoidCallback onCancelled;

  const PayPalWebViewScreen({
    super.key,
    required this.approvalUrl,
    required this.orderId,
    required this.provider,
    required this.onSuccess,
    required this.onCancelled,
  });

  @override
  State<PayPalWebViewScreen> createState() => _PayPalWebViewScreenState();
}

class _PayPalWebViewScreenState extends State<PayPalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handled = false;

  static const _returnUrl = 'https://example.com/payment/return';
  static const _cancelUrl = 'https://example.com/payment/cancel';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          if (request.url.startsWith(_returnUrl)) {
            _handleReturn();
            return NavigationDecision.prevent;
          }
          if (request.url.startsWith(_cancelUrl)) {
            _handleCancel();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  Future<void> _handleReturn() async {
    if (_handled) return;
    _handled = true;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await widget.provider.captureOrder(widget.orderId);
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog
      Navigator.pop(context); // close WebView
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog
      Navigator.pop(context); // close WebView
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _handleCancel() {
    if (_handled) return;
    _handled = true;
    Navigator.pop(context);
    widget.onCancelled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
