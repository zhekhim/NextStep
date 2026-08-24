import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';

class NearbyIndustryScreen extends StatefulWidget {
  const NearbyIndustryScreen({
    super.key,
    this.locationService = const LocationService(),
  });

  final LocationService locationService;

  @override
  State<NearbyIndustryScreen> createState() => _NearbyIndustryScreenState();
}

class _NearbyIndustryScreenState extends State<NearbyIndustryScreen> {
  static const _states = <String>[
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Penang', 'Perak', 'Perlis', 'Putrajaya',
    'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  Position? _position;
  String? _selectedState;
  LocationFailure? _failure;
  bool _isLoading = false;

  Future<void> _useCurrentLocation() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    try {
      final position = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _selectedState = null;
      });
    } on LocationFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _position != null || _selectedState != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities Near Me')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Find nearby opportunities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Allow location access to find career and industry insights near you.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _useCurrentLocation,
                        icon: _isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _isLoading ? 'Getting location...' : 'Use My Location',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 16),
              _LocationError(
                failure: _failure!,
                onOpenSettings:
                    _failure!.type == LocationFailureType.permissionDeniedForever
                    ? widget.locationService.openAppSettings
                    : _failure!.type == LocationFailureType.servicesDisabled
                    ? widget.locationService.openLocationSettings
                    : null,
              ),
            ],
            const SizedBox(height: 24),
            Text('Or select a state', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State or federal territory',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: _states
                  .map((state) => DropdownMenuItem(value: state, child: Text(state)))
                  .toList(),
              onChanged: (state) {
                setState(() {
                  _selectedState = state;
                  _position = null;
                  _failure = null;
                });
              },
            ),
            const SizedBox(height: 24),
            if (hasLocation) _buildSelectedLocation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLocation(BuildContext context) {
    final position = _position;
    final locationText = position == null
        ? _selectedState!
        : '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected location', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(locationText, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text(
              'Location is ready. Nearby opportunity results will appear here when location-based industry data is connected.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({required this.failure, this.onOpenSettings});

  final LocationFailure failure;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(failure.message),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onOpenSettings!(),
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
