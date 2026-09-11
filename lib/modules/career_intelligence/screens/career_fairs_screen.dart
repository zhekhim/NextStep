import 'package:flutter/material.dart';

import '../models/career_fair.dart';
import '../repositories/career_fair_repository.dart';
import '../widgets/career_fair_card.dart';
import 'career_fair_detail_screen.dart';

class CareerFairsScreen extends StatefulWidget {
  const CareerFairsScreen({super.key, this.repository, this.detailBuilder});

  final CareerFairRepository? repository;
  final Widget Function(CareerFair careerFair)? detailBuilder;

  @override
  State<CareerFairsScreen> createState() => _CareerFairsScreenState();
}

class _CareerFairsScreenState extends State<CareerFairsScreen> {
  late final CareerFairRepository _repository;
  List<CareerFair> _careerFairs = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseCareerFairRepository();
    _load();
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_repository case final SupabaseCareerFairRepository repository) {
        try {
          final cached = await repository.getCachedCareerFairs();
          if (cached.isNotEmpty && mounted) {
            final today = SupabaseCareerFairRepository.malaysiaToday(
              DateTime.now(),
            );
            final upcoming =
                cached.where((fair) => !fair.eventDate.isBefore(today)).toList()
                  ..sort(SupabaseCareerFairRepository.compareUpcoming);
            setState(() => _careerFairs = upcoming);
          }
        } catch (_) {
          // Continue with the online source when the local cache cannot open.
        }
      }
      final fairs = await _repository.getUpcomingCareerFairs();
      if (mounted) setState(() => _careerFairs = fairs);
    } catch (error) {
      debugPrint('Unable to load career fairs: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load career fairs.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career Fairs')),
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _careerFairs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading career fairs...'),
          ],
        ),
      );
    }
    if (_errorMessage != null && _careerFairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Upcoming Career Fairs',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore verified upcoming career fairs and recruitment events.',
          ),
          const SizedBox(height: 20),
          if (_careerFairs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No upcoming career fairs are currently available.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final fair in _careerFairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CareerFairCard(
                  careerFair: fair,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          widget.detailBuilder?.call(fair) ??
                          CareerFairDetailScreen(careerFair: fair),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
