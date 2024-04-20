import 'package:flutter/material.dart';

class GreyDescription extends StatelessWidget {
  final String desciption;
  const GreyDescription(this.desciption, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      desciption,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}
