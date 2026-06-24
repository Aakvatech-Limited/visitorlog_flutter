// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_shop/components/model/Employee.dart';

import 'package:ui_shop/components/common/custom_form_button.dart';
import 'package:ui_shop/components/common/custom_input_field.dart';

import 'common/custom_select_field.dart';
import 'common/page_text.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'common/qr_scanner_screen.dart';

import 'model/Visitor.dart';

class VisitorPageSearch extends StatefulWidget {
  const VisitorPageSearch({
    Key? key,
  }) : super(key: key);

  @override
  State<VisitorPageSearch> createState() => _VisitorPageSearchState();
}

class _VisitorPageSearchState extends State<VisitorPageSearch> {
  List<Visistor> _allVisitors = [];
  List<Visistor> _foundVisitor = [];
  String _scanBarcode = 'Unknown';

  final baseUrl = 'https://demo15.aakvaerp.com';
  final authToken = 'token 12b59d64ab0f102:0e59fedfef8c2e8';

  void _runFilter(String keyWord) {
    List<Visistor> result = [];
    if (keyWord.isEmpty) {
      result = _allVisitors;
    } else {
      result = _allVisitors
          .where((user) =>
              user.full_name.toLowerCase().contains(keyWord.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundVisitor = result;
    });
  }

  Future<void> scanQR(String id, String log_type, String full_name) async {
    String barcodeScanRes = '';
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(
            title: 'Scan Visitor Card',
            instruction: 'Align the visitor card QR code inside the frame',
          ),
        ),
      );
      barcodeScanRes = result ?? '';
      print(barcodeScanRes);
    } catch (e) {
      barcodeScanRes = 'Failed to scan barcode.';
    }
    if (!mounted) return;

    final uri = Uri.parse('$baseUrl/api/method/visitor.api.visitor_scan.visitors_scan');
    final response = await http.post(uri,
        body: {'qr_code': barcodeScanRes, 'api_type': 'search', 'log_name': id},
        headers: {'Authorization': authToken});
    final body = response.body;
    final json = jsonDecode(body);

    final log = json['message'];
    print(log);

    if (log['status'] == "card_not_existing") {
      _showResultDialog(
        icon: Icons.credit_card_off_outlined,
        iconColor: Colors.orange,
        title: 'Card Not Found',
        message: 'This card does not exist in the system.',
      );
      return;
    }

    if (log['status'] == "card_in_use") {
      _showResultDialog(
        icon: Icons.warning_amber_outlined,
        iconColor: Colors.amber.shade700,
        title: 'Card In Use',
        message: 'This card is already assigned to another visitor.',
      );
      return;
    }

    if (log['status'] == "visitor_is_in") {
      _showResultDialog(
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        title: 'Already Checked In',
        message: '$full_name is already inside.',
      );
      return;
    }

    if (log['status'] == "card_signed_in") {
      _showResultDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'Signed In',
        message: 'Card signed in successfully. Have a nice visit!',
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
      barrierDismissible: false,
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
                },
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Search Visitor",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(170, 170, 185, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  onChanged: (value) => _runFilter(value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type to search...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search,
                        color: Color.fromRGBO(170, 170, 185, 1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color.fromRGBO(170, 170, 185, 1), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final uri = Uri.parse(
                      '$baseUrl/api/resource/Visitors Registration Log?fields=["full_name", "contact_number", "name", "log_type"]&limit=10000');
                  final response = await http
                      .get(uri, headers: {'Authorization': authToken});
                  final body = response.body;
                  final json = jsonDecode(body);
                  final datas = json['data'] as List<dynamic>;
                  print(datas);
                  final transformed = datas.map((e) {
                    return Visistor(
                        full_name: e['full_name'],
                        contact_number: e['contact_number'],
                        name: e['name'],
                        log_type: e['log_type']);
                  }).toList();
                  setState(() {
                    _allVisitors = transformed;
                    _foundVisitor = _allVisitors;
                  });
                  return Future<void>.delayed(const Duration(seconds: 2));
                },
                child: ListView.builder(
                  itemCount: _foundVisitor.length,
                  itemBuilder: (context, index) => Card(
                    color: Color.fromRGBO(170, 170, 185, 1),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        _foundVisitor[index].full_name,
                        style: const TextStyle(
                            color: Color.fromRGBO(13, 29, 56, 1),
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _foundVisitor[index].contact_number,
                        style: const TextStyle(
                            color: Color.fromRGBO(13, 29, 56, 1)),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color.fromRGBO(13, 29, 56, 1)),
                      onTap: () {
                        scanQR(
                          _foundVisitor[index].name,
                          _foundVisitor[index].log_type,
                          _foundVisitor[index].full_name,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
