// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_shop/components/model/Employee.dart';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'common/qr_scanner_screen.dart';

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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(
            title: 'Scan Card QR',
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
        body: {'qr_code': barcodeScanRes, 'api_type': 'register'},
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
        message: 'This card is currently assigned to another visitor.',
      );
      return;
    }

    if (log['status'] == "card_signed_out") {
      _showResultDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'Signed Out',
        message: 'Card signed out successfully. Ready for the next visitor.',
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

      String? uploadedImageUrl;

      if (profileImage != null) {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$baseUrl/api/method/upload_file'));
        request.files
            .add(await http.MultipartFile.fromPath('file', profileImage.path));
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = authToken;
        try {
          final response = await request.send();
          final responseBody = await response.stream.bytesToString();

          if (response.statusCode == 200) {
            final responseData = jsonDecode(responseBody);
            uploadedImageUrl = responseData['message']['file_url'];
            print('File uploaded successfully.');
          } else {
            print('Failed to upload file. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error uploading file: $e');
        }
      }

      // Now create the registration log (with or without image)
      final uri = Uri.parse('$baseUrl/api/resource/Visitors Registration Log');
      final bodyData = {
        'full_name': widget.fullName ?? '',
        'contact_number': widget.contactNumber ?? '',
        'address': widget.address ?? '',
        'purpose': widget.purpose ?? '',
        'employee': employee,
        'log_type': 'IN',
        'qr_code': barcodeScanRes
      };
      
      if (uploadedImageUrl != null) {
        bodyData['visitor_image'] = uploadedImageUrl;
      }

      try {
        await http.post(uri, body: bodyData, headers: {
          'Authorization': authToken
        });
      } catch (e) {
        print('Error saving log: $e');
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      _showResultDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'Visitor Registered',
        message: 'Card registered successfully. The visitor may now proceed.',
      );
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

  // Confirm dialog before sending — now shows both name and ID clearly
  Future<void> _showMyDialog(String employee_id, String employee_name) async {
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
              const Icon(
                Icons.person_outline,
                size: 44,
                color: Color.fromRGBO(13, 29, 56, 1),
              ),
              const SizedBox(height: 12),
              const Text(
                'Confirm Host',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(13, 29, 56, 1),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Send visitor to:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffEEF1F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee_name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color.fromRGBO(13, 29, 56, 1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee_id,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                      _sendVisotors(employee_id);
                    },
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Result dialog with icon + title + message
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

  final _signupFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    const brandColor = Color.fromRGBO(13, 29, 56, 1);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: Column(
          children: [
            // ── Page header card (same as Search Visitor) ──────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: brandColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_alt_outlined,
                            color: brandColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Host',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: brandColor,
                            ),
                          ),
                          Text(
                            'Choose who the visitor is meeting',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextFormField(
                    onChanged: (value) => _runFilter(value),
                    decoration: InputDecoration(
                      hintText: 'Type to search...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: brandColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: brandColor, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xffF5F6FA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Employee list ────────────────────────────────
            Expanded(
              child: _foundEmployee.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: brandColor,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading employees...',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: _foundEmployee.length,
                      itemBuilder: (context, index) {
                        final emp = _foundEmployee[index];
                        final initial = emp.employee_name.isNotEmpty
                            ? emp.employee_name[0].toUpperCase()
                            : '?';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor:
                                  brandColor.withOpacity(0.1),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: brandColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              emp.employee_name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: brandColor,
                              ),
                            ),
                            subtitle: Text(
                              emp.employee,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              _showMyDialog(
                                emp.employee,
                                emp.employee_name,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignupUser() {
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting data..')),
      );
    }
  }
}
