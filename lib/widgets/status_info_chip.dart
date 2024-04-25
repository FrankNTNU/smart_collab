import 'package:flutter/material.dart';

class StatusInfoChip extends StatelessWidget {
  const StatusInfoChip({super.key, required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(5)),
      child: Text(
        status,
        style: TextStyle(
          color: color, // bold
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
