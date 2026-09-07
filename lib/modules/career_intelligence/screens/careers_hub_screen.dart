import 'package:flutter/material.dart';

import 'career_explorer_screen.dart';
import 'career_feature_placeholder_screen.dart';
import 'career_interest_types_screen.dart';
import 'interested_careers_screen.dart';
import 'labour_market_screen.dart';

class CareersHubScreen extends StatelessWidget {
  const CareersHubScreen({
    super.key,
    this.exploreBuilder,
    this.interestedCareersBuilder,
    this.interestTypesBuilder,
    this.labourMarketBuilder,
  });

  final WidgetBuilder? exploreBuilder;
  final WidgetBuilder? interestedCareersBuilder;
  final WidgetBuilder? interestTypesBuilder;
  final WidgetBuilder? labourMarketBuilder;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _CareerDestination(
        title: 'Explore Careers',
        description: 'Browse careers and review their required skills.',
        icon: Icons.work_outline,
        builder: exploreBuilder ?? (_) => const CareerExplorerScreen(),
      ),
      _CareerDestination(
        title: 'Interested Careers',
        description: 'Save and organise careers that interest you.',
        icon: Icons.bookmark_outline,
        builder:
            interestedCareersBuilder ?? (_) => const InterestedCareersScreen(),
      ),
      _CareerDestination(
        title: 'Career Fairs',
        description: 'Discover upcoming career events.',
        icon: Icons.event_outlined,
        builder: (_) => const CareerFeaturePlaceholderScreen(
          title: 'Career Fairs',
          message: 'Career Fairs will be implemented in a later phase.',
          icon: Icons.event_outlined,
        ),
      ),
      _CareerDestination(
        title: 'Career Interest Types',
        description: 'Learn about career-interest personality types.',
        icon: Icons.psychology_outlined,
        builder:
            interestTypesBuilder ?? (_) => const CareerInterestTypesScreen(),
      ),
      _CareerDestination(
        title: 'Malaysia Labour Market',
        description: 'Review official Malaysian labour-force statistics.',
        icon: Icons.insights_outlined,
        builder: labourMarketBuilder ?? (_) => const LabourMarketScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: destinations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final destination = destinations[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Icon(destination.icon),
                title: Text(destination.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(destination.description),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: destination.builder)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CareerDestination {
  const _CareerDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}
