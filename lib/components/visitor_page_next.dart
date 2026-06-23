// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_shop/components/model/Employee.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'home.dart';

class VisitorPageNext extends StatefulWidget {
  final String? fullName;
  final String? contactNumber;
  final String? address;
  final String? purpose;
  final File? profileImage;

  const VisitorPageNext({
    Key? key,
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.purpose,
    required this.profileImage,
  }) : super(key: key);

  @override
  State<VisitorPageNext> createState() => _VisitorPageNextState();
}

class _VisitorPageNextState extends State<VisitorPageNext> {
  List<Employee> _allEmployee = [];
  List<Employee> _foundEmployee = [];
  @override
  void initState() {
    fetch_user().then((value) {
      setState(() {
        _allEmployee = value;
        _foundEmployee = _allEmployee;
      });
    });
    super.initState();
  }

  void _runFilter(String keyWord) {
    List<Employee> result = [];
    if (keyWord.isEmpty) {
      result = _allEmployee;
    } else {
      result = _allEmployee
          .where((user) =>
              user.employee_name.toLowerCase().contains(keyWord.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundEmployee = result;
    });
  }

  Future<void> _sendVisotors(String employee) async {
    String barcodeScanRes = '';
    const baseUrl = 'https://demo15.aakvaerp.com';
    const authToken = 'token 12b59d64ab0f102:0e59fedfef8c2e8';

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

    final uri = Uri.parse('$baseUrl/api/method/visitor.api.visitor_scan.visitors_scan');
    final response = await http.post(uri,
        body: {'qr_code': barcodeScanRes, 'api_type': 'register'},
        headers: {'Authorization': authToken});
    final body = response.body;
    final json = jsonDecode(body);

    final log = json['message'];
    print(log);

    if (log['status'] == "card_not_existing") {
      _showMyDialogMessage("This Card not existing.");
      return;
    }

    if (log['status'] == "card_in_use") {
      _showMyDialogMessage("This Card is in use.");
      return;
    }

    if (log['status'] == "card_signed_out") {
      _showMyDialogMessage(
          "This Card has Successfully been signed out. Ready to be used by another visitor.");
      return;
    }

    if (log['status'] == "set_api_type") {
      _showMyDialogMessage("set_api_type.");
      return;
    }

    if (log['status'] == "card_to_created") {
      File? profileImage = widget.profileImage;

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });

      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/api/method/upload_file'));
      request.files
          .add(await http.MultipartFile.fromPath('file', profileImage!.path));
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = authToken;
      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final responseData = jsonDecode(responseBody);
          final uri =
              Uri.parse('$baseUrl/api/resource/Visitors Registration Log');
          final response = await http.post(uri, body: {
            'full_name': widget.fullName,
            'contact_number': widget.contactNumber,
            'address': widget.address,
            'purpose': widget.purpose,
            'employee': employee,
            'visitor_image': responseData['message']['file_url'],
            'log_type': 'IN',
            'qr_code': barcodeScanRes
          }, headers: {
            'Authorization': authToken
          });
          print('File uploaded successfully.');
        } else {
          print('Failed to upload file. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      _showMyDialogMessage("Card registered, Visitor can procced.");
      return;
    }
  }

  fetch_user() async {
    const url =
        'https://demo15.aakvaerp.com/api/resource/Employee?fields=["employee_name", "employee"]&limit=10000';
    final uri = Uri.parse(url);
    final response = await http.get(uri,
        headers: {'Authorization': 'token 12b59d64ab0f102:0e59fedfef8c2e8'});
    final body = response.body;
    final json = jsonDecode(body);
    final datas = json['data'] as List<dynamic>;
    final transformed = datas.map((e) {
      return Employee(
          employee_name: e['employee_name'], employee: e['employee']);
    }).toList();
    return transformed;
  }

  Future<void> _showMyDialog(String employee_id, String employee_name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure want to send to?"),
          content: Text(employee_id),
          actions: <Widget>[
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                _sendVisotors(employee_id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMyDialogMessage(String message) async {
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

  final _signupFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: const Color(0xffEEF1F3),
            body: Padding(
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
                            "Search Host",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: ListView.builder(
                        itemCount: _foundEmployee.length,
                        itemBuilder: (context, index) => Card(
                          color: const Color(0xff233743),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            title: Text(
                              _foundEmployee[index].employee_name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              _foundEmployee[index].employee,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              _showMyDialog(_foundEmployee[index].employee,
                                  _foundEmployee[index].employee_name);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ))));
  }

  void _handleSignupUser() {
    // signup user
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting data..')),
      );
    }
  }
}
