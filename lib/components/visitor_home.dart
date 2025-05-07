import 'package:flutter/material.dart';
import 'package:ui_shop/components/common/page_header.dart';
import 'package:ui_shop/components/common/page_heading.dart';

class VisitorHome extends StatefulWidget {
  const VisitorHome({Key? key}) : super(key: key);

  @override
  State<VisitorHome> createState() => _VisitorHomeState();
}

class _VisitorHomeState extends State<VisitorHome> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Column(
              children: [
                PageHeading(
                  title: 'Welcome to our Visitor App',
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 18,
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
