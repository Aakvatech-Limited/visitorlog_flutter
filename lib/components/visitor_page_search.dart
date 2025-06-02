// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_shop/components/common/page_header.dart';
import 'package:ui_shop/components/common/page_heading.dart';
import 'package:ui_shop/components/login_page.dart';

import 'package:ui_shop/components/common/custom_form_button.dart';
import 'package:ui_shop/components/common/custom_input_field.dart';
import 'package:ui_shop/components/model/Employee.dart';

import 'common/custom_select_field.dart';
import 'common/page_text.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'model/Visitor.dart';
// import 'package:flutter_animated_button/flutter_animated_button.dart';
// import 'package:awesome_dialog/awesome_dialog.dart';

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

  final baseUrl = 'http://192.168.1.112:8000';
  final authToken = 'token 2f01ca5678d9c64:127583f0e7fb556';

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
      // Navigate to scanner page and wait for result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                Navigator.pop(context, barcodes.first.rawValue ?? '');
              }
            },
          ),
        ),
      );
      barcodeScanRes = result ?? '';
      print(barcodeScanRes);
    } catch (e) {
      barcodeScanRes = 'Failed to scan barcode.';
    }
    if (!mounted) return;

    final uri = Uri.parse('$baseUrl/api/method/visitors_scan');
    final response = await http.post(uri,
        body: {'qr_code': barcodeScanRes, 'api_type': 'search', 'log_name': id},
        headers: {'Authorization': authToken});
    final body = response.body;
    final json = jsonDecode(body);

    final log = json['message'];
    print(log);

    if (log['status'] == "card_not_existing") {
      _showMyDialog("This Card not existing.");
      return;
    }

    if (log['status'] == "card_in_use") {
      _showMyDialog("This Card is in use.");
      return;
    }

    if (log['status'] == "visitor_is_in") {
      _showMyDialog("$full_name is Already in.");
      return;
    }

    if (log['status'] == "card_signed_in") {
      _showMyDialog(
          "This Card has Successfully been signed IN. Have i nice visit.");
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
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
            const SizedBox(
              height: 16,
            ),
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
                TextFormField(
                  onChanged: (value) => _runFilter(value),
                  decoration: const InputDecoration(
                    hintText: "Enter",
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
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
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(
                        _foundVisitor[index].full_name,
                        style: const TextStyle(
                            color: Color.fromRGBO(13, 29, 56, 1)),
                      ),
                      subtitle: Text(
                        _foundVisitor[index].contact_number,
                        style: const TextStyle(
                            color: Color.fromRGBO(13, 29, 56, 1)),
                      ),
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
