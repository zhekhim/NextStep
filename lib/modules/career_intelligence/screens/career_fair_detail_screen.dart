import 'package:flutter/material.dart';

import '../models/career_fair.dart';
import '../services/career_fair_formatter.dart';

class CareerFairDetailScreen extends StatelessWidget {
  const CareerFairDetailScreen({required this.careerFair, super.key});

  final CareerFair careerFair;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career Fair Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              careerFair.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(careerFair.organiser),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Date',
              child: Text(CareerFairFormatter.date(careerFair.eventDate)),
            ),
            _DetailSection(
              title: 'Time',
              child: Text(CareerFairFormatter.timeRange(careerFair)),
            ),
            _DetailSection(title: 'Venue', child: Text(careerFair.venue)),
            _DetailSection(title: 'Address', child: Text(careerFair.address)),
            _DetailSection(
              title: 'About This Event',
              child: Text(careerFair.description),
            ),
            if (careerFair.registrationUrl != null)
              _DetailSection(
                title: 'Registration',
                child: SelectableText(careerFair.registrationUrl!),
              ),
            if (careerFair.sourceUrl != null)
              _DetailSection(
                title: 'Verified Source',
                child: SelectableText(careerFair.sourceUrl!),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
