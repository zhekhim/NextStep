import 'package:flutter/material.dart';

import '../models/labour_force_statistic.dart';
import '../repositories/labour_market_repository.dart';

typedef LabourMarketLoader = Future<List<LabourForceStatistic>> Function();

class LabourMarketScreen extends StatefulWidget {
  const LabourMarketScreen({super.key, this.loadStatistics});

  final LabourMarketLoader? loadStatistics;

  @override
  State<LabourMarketScreen> createState() => _LabourMarketScreenState();
}

class _LabourMarketScreenState extends State<LabourMarketScreen> {
  List<LabourForceStatistic> _statistics = const [];
  LabourForceStatistic? _selectedStatistic;
  bool _isLoading = false;
  String? _errorMessage;

  LabourMarketLoader get _loadFromSource =>
      widget.loadStatistics ??
      LabourMarketRepository().getRecentMonthlyStatistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final statistics = await _loadFromSource();
      if (!mounted) return;
      setState(() {
        _statistics = statistics;
        _selectedStatistic = statistics.isEmpty ? null : statistics.first;
      });
    } catch (error) {
      debugPrint('Unable to load labour market data: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load labour market data.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Malaysia Labour Market')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Official monthly labour-force statistics for Malaysia.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Source: data.gov.my\nDepartment of Statistics Malaysia',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _statistics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading labour market data...'),
            ],
          ),
        ),
      );
    }
    if (_errorMessage != null && _statistics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _loadStatistics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _selectedStatistic;
    if (selected == null) {
      return const Center(child: Text('No labour market data available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<LabourForceStatistic>(
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Month',
            border: OutlineInputBorder(),
          ),
          items: _statistics
              .map(
                (statistic) => DropdownMenuItem(
                  value: statistic,
                  child: Text(_formatMonth(statistic.date)),
                ),
              )
              .toList(),
          onChanged: (statistic) {
            if (statistic != null) {
              setState(() => _selectedStatistic = statistic);
            }
          },
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _StatisticCard(
              label: 'Employed Persons',
              value: '${(selected.employed / 1000).toStringAsFixed(2)} million',
            ),
            _StatisticCard(
              label: 'Unemployed Persons',
              value: '${selected.unemployed.toStringAsFixed(1)} thousand',
            ),
            _StatisticCard(
              label: 'Unemployment Rate',
              value: '${selected.unemploymentRate.toStringAsFixed(1)}%',
            ),
            _StatisticCard(
              label: 'Labour Force Participation Rate',
              value: '${selected.participationRate.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
