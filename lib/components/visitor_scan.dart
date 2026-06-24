import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import 'home.dart';

class VisitorScan extends StatefulWidget {
  const VisitorScan({
    Key? key,
  }) : super(key: key);
  @override
  State<VisitorScan> createState() => _VisitorScanState();
}

class _VisitorScanState extends State<VisitorScan> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scanQR();
    });
  }

  final baseUrl = 'https://demo15.aakvaerp.com';
  final authToken = 'token 12b59d64ab0f102:0e59fedfef8c2e8';

  Future<void> scanQR() async {
    String barcodeScanRes = '';
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            bool isScanned = false;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Scan QR Code'),
                backgroundColor: Color.fromRGBO(13, 29, 56, 1),
                foregroundColor: Colors.white,
              ),
              body: MobileScanner(
                onDetect: (capture) {
                  if (isScanned) return;
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    isScanned = true;
                    Navigator.pop(context, barcodes.first.rawValue ?? '');
                  }
                },
              ),
            );
          },
        ),
      );
      barcodeScanRes = result ?? '';
    } catch (e) {
      barcodeScanRes = 'Failed to scan barcode.';
    }
    if (!mounted) return;

    final uri = Uri.parse('$baseUrl/api/method/visitor.api.visitor_scan.visitors_scan');
    final response = await http.post(uri,
        body: {'qr_code': barcodeScanRes, 'api_type': 'scan'},
        headers: {'Authorization': authToken});
    final body = response.body;
    final json = jsonDecode(body);

    final log = json['message'];
    print("Response body: $body");
    print("Parsed log: $log");

    if (log == null) {
      _showResultDialog(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Server Error',
        message: 'Invalid response. Please try again.',
      );
      return;
    }

    if (log['status'] == "card_not_existing") {
      _showResultDialog(
        icon: Icons.credit_card_off_outlined,
        iconColor: Colors.orange,
        title: 'Card Not Found',
        message: 'This card does not exist in the system.',
      );
      return;
    }

    if (log['status'] == "card_not_in_use") {
      _showResultDialog(
        icon: Icons.info_outline,
        iconColor: Colors.blueGrey,
        title: 'Card Not Active',
        message: 'This card is currently not in use.',
      );
      return;
    }

    if (log['status'] == "card_signed_out") {
      _showResultDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'Signed Out',
        message: 'Visitor signed out successfully. Card is ready for the next visitor.',
      );
      return;
    }

    if (log['status'] == "set_api_type") {
      _showResultDialog(
        icon: Icons.settings_outlined,
        iconColor: Colors.grey,
        title: 'Configuration',
        message: 'API type needs to be set.',
      );
      return;
    }
  }

  Future<void> _showResultDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 48),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(13, 29, 56, 1),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color.fromRGBO(13, 29, 56, 1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Home()));
                },
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future _showLoading() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _sendToErpnext(String code) async {
    _showLoading();
    const baseUrl = 'https://demo15.aakvaerp.com';
    const authToken = 'token 12b59d64ab0f102:0e59fedfef8c2e8';

    final uri = Uri.parse('$baseUrl/api/method/visitor.api.visitor_scan.register_visitor');
    final response = await http.post(uri,
        body: {'code': code, 'log_type': widget.toString()},
        headers: {'Authorization': authToken});
    final body = response.body;
    Navigator.of(context).pop();
    _showResultDialog(
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      title: 'Response',
      message: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Loading...",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLoginUser() {}
}
