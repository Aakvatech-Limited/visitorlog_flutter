import 'package:flutter/material.dart';

class PageText extends StatelessWidget {
  final String text;
  const PageText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontFamily: 'NotoSerif'),
      ),
    );
  }
}
