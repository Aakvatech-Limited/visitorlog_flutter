import 'package:flutter/material.dart';
import 'package:ui_shop/components/common/custom_input_field.dart';
import 'package:ui_shop/components/common/page_header.dart';
import 'package:ui_shop/components/forget_password_page.dart';
import 'package:ui_shop/components/signup_page.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ui_shop/components/common/page_heading.dart';

import 'package:ui_shop/components/common/custom_form_button.dart';
import 'package:ui_shop/components/visitor_page.dart';
import 'package:ui_shop/components/visitor_page_search.dart';
import 'package:ui_shop/components/visitor_scan.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'login_page.dart';
import 'visitor_home.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _loginFormKey = GlobalKey<FormState>();
  String selectedLanguage = 'English';
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    VisitorHome(),
    VisitorScan(),
    VisitorPageSearch(),
    VisitorPage(),
  ];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(13, 29, 56, 1),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(.1),
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Color.fromRGBO(13, 29, 56, 1),
                tabs: const [
                  GButton(
                    icon: Icons.home_outlined,
                    text: 'Home',
                  ),
                  GButton(
                    icon: Icons.qr_code_2,
                    text: 'Scan',
                  ),
                  GButton(
                    icon: Icons.search,
                    text: 'Search',
                  ),
                  GButton(
                    icon: Icons.person_outline,
                    text: 'Register',
                  ),
                ],
                color: Color.fromRGBO(13, 29, 56, 1),
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLoginUser() {
    if (_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting data..')),
      );
    }
  }
}
