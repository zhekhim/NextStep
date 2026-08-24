import 'package:flutter/material.dart';

import '../models/career.dart';
import '../models/labour_force_statistic.dart';
import '../repositories/career_repository.dart';
import '../repositories/labour_market_repository.dart';
import '../widgets/career_card.dart';
import 'career_detail_screen.dart';
import 'nearby_industry_screen.dart';

class CareerExplorerScreen extends StatefulWidget {
  const CareerExplorerScreen({super.key});

  @override
  State<CareerExplorerScreen> createState() => _CareerExplorerScreenState();
}

class _CareerExplorerScreenState extends State<CareerExplorerScreen> {
  final LabourMarketRepository _labourRepository = LabourMarketRepository();
  final CareerRepository _careerRepository = CareerRepository();

  List<LabourForceStatistic> _statistics = const [];
  LabourForceStatistic? _selectedStatistic;
  bool _isLoading = false;
  String? _errorMessage;
  List<Career> _careers = const [];
  bool _areCareersLoading = false;
  String? _careersErrorMessage;
  String _searchQuery = '';
  String _selectedCategory = _allCategories;

  static const String _allCategories = 'All Categories';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadCareers();
  }

  Future<void> _loadStatistics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statistics = await _labourRepository.getRecentMonthlyStatistics();
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

  Future<void> _loadCareers() async {
    if (_areCareersLoading) return;

    setState(() {
      _areCareersLoading = true;
      _careersErrorMessage = null;
    });

    try {
      final careers = await _careerRepository.getCareers();
      if (!mounted) return;
      setState(() {
        _careers = careers;
        final categories = careers.map((career) => career.category).toSet();
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = _allCategories;
        }
      });
    } catch (error) {
      debugPrint('Unable to load careers: $error');
      if (mounted) {
        setState(() => _careersErrorMessage = 'Unable to load careers.');
      }
    } finally {
      if (mounted) setState(() => _areCareersLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
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
                'Government Data Source - data.gov.my',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NearbyIndustryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Opportunities Near Me'),
              ),
              const SizedBox(height: 20),
              _buildContent(),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Career Explorer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildCareerExplorer(),
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

  String _formatMillions(double valueInThousands) {
    return '${(valueInThousands / 1000).toStringAsFixed(2)} million';
  }

  String _formatThousands(double value) {
    return '${value.toStringAsFixed(1)} thousand';
  }

  String _formatRate(double value) => '${value.toStringAsFixed(1)}%';

  Widget _buildCareerExplorer() {
    if (_areCareersLoading && _careers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading careers...'),
            ],
          ),
        ),
      );
    }

    if (_careersErrorMessage != null && _careers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(_careersErrorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _areCareersLoading ? null : _loadCareers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final categories =
        _careers.map((career) => career.category).toSet().toList()..sort();
    final filteredCareers = _careers.where((career) {
      final matchesSearch = career.careerName.toLowerCase().contains(
        _searchQuery.trim().toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == _allCategories ||
          career.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search careers...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [_allCategories, ...categories]
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
          onChanged: (category) {
            if (category != null) {
              setState(() => _selectedCategory = category);
            }
          },
        ),
        const SizedBox(height: 16),
        if (filteredCareers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('No careers found.'),
          )
        else
          ...filteredCareers.map(
            (career) => CareerCard(
              career: career,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CareerDetailScreen(career: career),
                  ),
                );
              },
            ),
          ),
      ],
    );
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
