import 'package:flutter/material.dart';

import '../models/career.dart';

class CareerCard extends StatelessWidget {
  const CareerCard({required this.career, required this.onTap, super.key});

  final Career career;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          career.careerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(career.category),
        ),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View Details'),
            SizedBox(width: 4),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
