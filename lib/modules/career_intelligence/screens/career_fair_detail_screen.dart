import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/career_fair.dart';
import '../services/career_fair_formatter.dart';
import '../services/career_fair_map_service.dart';

typedef AddressCopier = Future<void> Function(String address);

class CareerFairDetailScreen extends StatefulWidget {
  const CareerFairDetailScreen({
    required this.careerFair,
    super.key,
    this.mapService,
    this.addressCopier,
  });

  final CareerFair careerFair;
  final CareerFairMapService? mapService;
  final AddressCopier? addressCopier;

  @override
  State<CareerFairDetailScreen> createState() => _CareerFairDetailScreenState();
}

class _CareerFairDetailScreenState extends State<CareerFairDetailScreen> {
  late final CareerFairMapService _mapService;
  late final AddressCopier _addressCopier;
  bool _openingMaps = false;

  CareerFair get careerFair => widget.careerFair;

  @override
  void initState() {
    super.initState();
    _mapService = widget.mapService ?? CareerFairMapService();
    _addressCopier =
        widget.addressCopier ??
        (address) => Clipboard.setData(ClipboardData(text: address));
  }

  Future<void> _openMaps() async {
    if (_openingMaps) return;
    setState(() => _openingMaps = true);
    final launched = await _mapService.launchLocation(careerFair);
    if (!mounted) return;
    setState(() => _openingMaps = false);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this location in Maps.')),
      );
    }
  }

  Future<void> _copyAddress() async {
    await _addressCopier(careerFair.address.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Address copied.')));
  }

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
            if (careerFair.hasUsableLocation) ...[
              FilledButton.icon(
                onPressed: _openingMaps ? null : _openMaps,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  _openingMaps ? 'Opening Maps...' : 'Open Venue in Maps',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (careerFair.address.trim().isNotEmpty)
              OutlinedButton.icon(
                onPressed: _copyAddress,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy Address'),
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
