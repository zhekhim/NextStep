import 'package:flutter/material.dart';

import '../models/labour_force_statistic.dart';
import '../repositories/labour_market_repository.dart';

class CareerExplorerScreen extends StatefulWidget {
  const CareerExplorerScreen({super.key});

  @override
  State<CareerExplorerScreen> createState() =>
      _CareerExplorerScreenState();
}

class _CareerExplorerScreenState extends State<CareerExplorerScreen> {
  final LabourMarketRepository _repository = LabourMarketRepository();

  List<LabourForceStatistic> _statistics = const [];
  LabourForceStatistic? _selectedStatistic;
  bool _isLoading = false;
  String? _errorMessage;

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
      final statistics = await _repository.getRecentMonthlyStatistics();
      if (!mounted) return;

      setState(() {
        _statistics = statistics;
        _selectedStatistic = statistics.isEmpty ? null : statistics.first;
      });
    } catch (error) {
      debugPrint('Unable to load labour market data: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load labour market data.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Careers'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Malaysia Labour Market',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Government Data Source · data.gov.my',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
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
              value: _formatMillions(selected.employed),
            ),
            _StatisticCard(
              label: 'Unemployed Persons',
              value: _formatThousands(selected.unemployed),
            ),
            _StatisticCard(
              label: 'Unemployment Rate',
              value: _formatRate(selected.unemploymentRate),
            ),
            _StatisticCard(
              label: 'Labour Force Participation Rate',
              value: _formatRate(selected.participationRate),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatMillions(double valueInThousands) {
    return '${(valueInThousands / 1000).toStringAsFixed(2)} million';
  }

  String _formatThousands(double value) {
    return '${value.toStringAsFixed(1)} thousand';
  }

  String _formatRate(double value) => '${value.toStringAsFixed(1)}%';
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
