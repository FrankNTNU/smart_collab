import 'package:flutter/material.dart';

class StatusInfoChip extends StatelessWidget {
  const StatusInfoChip({super.key, required this.status, required this.color, this.isSmall = false});
  final String status;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: isSmall ? 2 : 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(5)),
      child: Text(
        status,
        style: TextStyle(
          color: color, // bold
          fontWeight: FontWeight.bold,
          fontSize: isSmall ? 12 : null,
        ),
      ),
    );
  }
}
