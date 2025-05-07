import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_shop/components/common/custom_input_field.dart';
import 'package:ui_shop/components/common/page_header.dart';
import 'package:ui_shop/components/forget_password_page.dart';
import 'package:ui_shop/components/signup_page.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ui_shop/components/common/page_heading.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import 'package:ui_shop/components/common/custom_form_button.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import 'home.dart';
import 'visitor_home.dart';

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
    scanQR();
  }

  final baseUrl = 'http://192.168.1.112:8000';
  final authToken = 'token 2f01ca5678d9c64:127583f0e7fb556';

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;

    final uri = Uri.parse('$baseUrl/api/method/visitors_scan');
    final response = await http.post(uri,
        body: {'qr_code': barcodeScanRes, 'api_type': 'scan'},
        headers: {'Authorization': authToken});
    final body = response.body;
    final json = jsonDecode(body);

    final log = json['message'];
    print(log);

    if (log['status'] == "card_not_existing") {
      _showMyDialog("This Card not existing.");
      return;
    }

    if (log['status'] == "card_not_in_use") {
      _showMyDialog("This Card not in use.");
      return;
    }

    if (log['status'] == "card_signed_out") {
      _showMyDialog(
          "This Card has Successfully been signed out. Ready to be used by another visitor.");
      return;
    }

    if (log['status'] == "set_api_type") {
      _showMyDialog("set_api_type.");
      return;
    }
  }

  Future<void> _showMyDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Home()));
              },
            ),
          ],
        );
      },
    );
  }

  Future _showLoading() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _sendToErpnext(String code) async {
    _showLoading();
    const baseUrl = 'http://192.168.1.112:8000';
    const authToken = 'token 2f01ca5678d9c64:127583f0e7fb556';

    final uri = Uri.parse('$baseUrl/api/method/visitors_registration');
    final response = await http.post(uri,
        body: {'code': code, 'log_type': "widget.logType"},
        headers: {'Authorization': authToken});
    final body = response.body;
    Navigator.of(context).pop();
    _showMyDialog(body);
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
