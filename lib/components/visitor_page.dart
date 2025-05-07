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
import 'package:ui_shop/components/visitor_home.dart';

import 'common/custom_select_field.dart';
import 'visitor_page_next.dart';
import 'package:permission_handler/permission_handler.dart';

class VisitorPage extends StatefulWidget {
  const VisitorPage({Key? key}) : super(key: key);

  @override
  State<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends State<VisitorPage> {
  File? _profileImage;

  String? _fullName = '';
  String? _contactNumber = '';
  String? _address = '';
  String? _purpose = '';

  final _signupFormKey = GlobalKey<FormState>();

  // Future _pickProfileImage() async {
  //   try {
  //     final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  //     if (image == null) return;

  //     final imageTemporary = File(image.path);
  //     setState(() => _profileImage = imageTemporary);
  //   } on PlatformException catch (e) {
  //     debugPrint('Failed to pick image error: $e');
  //   }
  // }

  // Future _pickProfileImage() async {
  //   try {
  //     final image = await ImagePicker().pickImage(source: ImageSource.camera);
  //     if (image == null) return;

  //     final imageTemporary = File(image.path);
  //     setState(() => _profileImage = imageTemporary);
  //   } on PlatformException catch (e) {
  //     debugPrint('Failed to pick image error: $e');
  //   }
  // }
  Future _pickProfileImage() async {
    // Request camera permission
    final cameraPermission = await Permission.camera.request();

    // Check if permission is granted
    if (cameraPermission.isGranted) {
      try {
        final image = await ImagePicker().pickImage(source: ImageSource.camera);
        if (image == null) return;

        final imageTemporary = File(image.path);
        setState(() => _profileImage = imageTemporary);
      } on PlatformException catch (e) {
        debugPrint('Failed to pick image error: $e');
      }
    } else {
      // Permission denied
      debugPrint('Camera permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: SingleChildScrollView(
          child: Form(
            key: _signupFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(
                        title: 'Visitors Registration',
                      ),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_sharp,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                          onSaved: (text) {
                            _fullName = text;
                          },
                          labelText: 'Full Name',
                          hintText: 'Visitor name',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Name field is required!';
                            }
                            return null;
                          }),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                          onSaved: (text) {
                            _contactNumber = text;
                          },
                          labelText: 'Contact No.',
                          hintText: 'Visitor contact number',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Contact number is required!';
                            }
                            return null;
                          }),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                          onSaved: (text) {
                            _address = text;
                          },
                          labelText: 'Address',
                          hintText: 'Visitor address',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'address is required!';
                            }
                            return null;
                          }),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                          onSaved: (text) {
                            _purpose = text;
                          },
                          labelText: 'Purpose',
                          hintText: 'Purpose of visit',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'purpose is required!';
                            }
                            return null;
                          }),
                      const SizedBox(
                        height: 22,
                      ),
                      CustomFormButton(
                        innerText: 'Next',
                        onPressed: _handleSignupUser,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignupUser() {
    // signup user
    if (_signupFormKey.currentState!.validate()) {
      _signupFormKey.currentState!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait..'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VisitorPageNext(
                    fullName: _fullName,
                    contactNumber: _contactNumber,
                    address: _address,
                    purpose: _purpose,
                    profileImage: _profileImage,
                  )));
    }
  }
}
