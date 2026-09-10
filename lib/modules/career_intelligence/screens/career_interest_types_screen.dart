import 'package:flutter/material.dart';

import '../models/riasec_type.dart';
import '../services/riasec_reference_service.dart';

class CareerInterestTypesScreen extends StatelessWidget {
  const CareerInterestTypesScreen({
    super.key,
    this.referenceService = const RiasecReferenceService(),
  });

  final RiasecReferenceService referenceService;

  @override
  Widget build(BuildContext context) {
    final types = referenceService.getTypes();
    return Scaffold(
      appBar: AppBar(title: const Text('Career Interest Types')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Explore the six RIASEC career-interest types used by Malaysia's Ministry of Higher Education e-Profiling system.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            for (final type in types) ...[
              _RiasecTypeCard(type: type),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              'Source:\nMinistry of Higher Education Malaysia (MOHE)\ne-Profiling\n${RiasecReferenceService.sourceUrl}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              RiasecReferenceService.translationNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiasecTypeCard extends StatelessWidget {
  const _RiasecTypeCard({required this.type});

  final RiasecType type;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('riasec-${type.code}'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                type.code,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(type.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
