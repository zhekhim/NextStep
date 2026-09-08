import 'package:flutter/material.dart';

import '../models/career_fair.dart';
import '../services/career_fair_formatter.dart';

class CareerFairCard extends StatelessWidget {
  const CareerFairCard({
    required this.careerFair,
    required this.onTap,
    super.key,
  });

  final CareerFair careerFair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(
          careerFair.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(careerFair.organiser),
              const SizedBox(height: 4),
              Text(CareerFairFormatter.date(careerFair.eventDate)),
              Text(CareerFairFormatter.timeRange(careerFair)),
              const SizedBox(height: 4),
              Text(careerFair.venue),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
